// Grant companions_tame to human actors on init (D4: hookTree, no SuperName climb)
::AC.HooksMod.hookTree("scripts/entity/tactical/human", function(q)
{
	q.onInit = @(__original) function()
	{
		__original();
		if (this.m.IsControlledByPlayer && !this.getSkills().hasSkill("actives.companions_tame"))
			this.m.Skills.add(this.new("scripts/companions/player/companions_tame"));
	}
});
