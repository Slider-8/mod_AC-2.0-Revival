// Do not replace setupUITooltip wholesale — MSU Nested Tooltips and Reforged
// also patch this. Only clamp vertical position so tall companion tooltips
// stay on screen after the existing implementation has laid them out.
(function ()
{
	if (typeof TooltipModule === "undefined" || !TooltipModule.prototype)
		return;

	var previous = TooltipModule.prototype.setupUITooltip;

	TooltipModule.prototype.setupUITooltip = function (_targetDIV, _data)
	{
		if (typeof previous === "function")
		{
			previous.call(this, _targetDIV, _data);
		}

		if (_targetDIV === undefined || this.mContainer === undefined || this.mContainer === null)
			return;

		var wnd = this.mParent;
		if (wnd === undefined || wnd === null || typeof wnd.height !== "function")
			return;

		var containerHeight = this.mContainer.outerHeight(true);
		var posTop = parseInt(this.mContainer.css("top"), 10);
		if (isNaN(posTop))
			return;

		if (posTop + containerHeight > wnd.height())
		{
			posTop = Math.max(0, wnd.height() - containerHeight);
			this.mContainer.css({ top: posTop });
		}
	};
})();
