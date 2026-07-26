"""Minimal CDP scraper against an already-running Brave on --remote-debugging-port=9222.

Usage: python cdp.py <url> [wait_seconds] [--keep]
Prints the rendered page text to stdout.
"""
import json
import sys
import time
import urllib.request

from websockets.sync.client import connect

PORT = 9222
_id = 0


def next_id():
    global _id
    _id += 1
    return _id


def send(ws, method, params=None, session=None):
    msg = {"id": next_id(), "method": method, "params": params or {}}
    if session:
        msg["sessionId"] = session
    ws.send(json.dumps(msg))
    while True:
        data = json.loads(ws.recv())
        if data.get("id") == msg["id"]:
            if "error" in data:
                raise RuntimeError(f"{method}: {data['error']}")
            return data.get("result", {})


def browser_ws():
    with urllib.request.urlopen(f"http://127.0.0.1:{PORT}/json/version", timeout=5) as r:
        return json.load(r)["webSocketDebuggerUrl"]


TEXT_EXPR = "document.title + '\\n@@URL@@' + location.href + '\\n' + document.body.innerText"


def scrape(url, wait=6.0, keep=False, expr=None):
    with connect(browser_ws(), max_size=200 * 1024 * 1024) as ws:
        target = send(ws, "Target.createTarget", {"url": url})["targetId"]
        try:
            session = send(
                ws, "Target.attachToTarget", {"targetId": target, "flatten": True}
            )["sessionId"]
            send(ws, "Page.enable", session=session)
            time.sleep(wait)
            # Cloudflare interstitials resolve on a delay; retry until real content shows.
            text = ""
            for _ in range(6):
                gate = send(
                    ws,
                    "Runtime.evaluate",
                    {"expression": TEXT_EXPR, "returnByValue": True},
                    session=session,
                ).get("result", {}).get("value", "") or ""
                if "Just a moment" not in gate and "security verification" not in gate:
                    if expr is None:
                        return gate
                    res = send(
                        ws,
                        "Runtime.evaluate",
                        {"expression": expr, "returnByValue": True, "awaitPromise": True},
                        session=session,
                    )
                    return res.get("result", {}).get("value", "")
                text = gate
                time.sleep(4)
            return text
        finally:
            if not keep:
                send(ws, "Target.closeTarget", {"targetId": target})


if __name__ == "__main__":
    url = sys.argv[1]
    wait = float(sys.argv[2]) if len(sys.argv) > 2 and not sys.argv[2].startswith("--") else 6.0
    expr = None
    if "--js" in sys.argv:
        expr = sys.argv[sys.argv.index("--js") + 1]
    out = scrape(url, wait, "--keep" in sys.argv, expr)
    print(out if isinstance(out, str) else json.dumps(out, indent=1))
