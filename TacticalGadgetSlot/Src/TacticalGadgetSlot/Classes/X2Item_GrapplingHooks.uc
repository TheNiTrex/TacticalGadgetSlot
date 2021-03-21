class X2Item_GrapplingHooks extends X2Item;

static function array<X2DataTemplate> CreateTemplates() {

	local array<X2DataTemplate> Items;

	// Create Grappling Hook Items for Light Armors:
	Items.AddItem(CreateGrapplingHook());
	Items.AddItem(CreateGrapplingHookPowered()); 

	return Items;

}

static function X2DataTemplate CreateGrapplingHook() { // Second Grapple Item because there's a separate ability for the Wraith Suit particle effects.

	local X2WeaponTemplate	Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'GrapplingHook');

	Template.strImage = "img:///UILibrary_TacticalGadgetSlot.Inv_PlatedGrapple2";
	Template.EquipSound = "StrategyUI_Heavy_Weapon_Equip";
	Template.InventorySlot = eInvSlot_TacticalGadget;
	Template.ItemCat = 'tacticalgadget';
	Template.WeaponCat = 'tacticalgadget';

	// Abilities:
	Template.Abilities.AddItem('Grapple');

	// Build:
	Template.CanBeBuilt = false;
	Template.StartingItem = true;
	Template.bInfiniteItem = true;

	return Template;

}

static function X2DataTemplate CreateGrapplingHookPowered() { 

	local X2WeaponTemplate	Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'GrapplingHookPowered');

	Template.strImage = "img:///UILibrary_TacticalGadgetSlot.Inv_PowGrapple2";
	Template.EquipSound = "StrategyUI_Heavy_Weapon_Equip";
	Template.InventorySlot = eInvSlot_TacticalGadget;
	Template.ItemCat = 'tacticalgadget';
	Template.WeaponCat = 'tacticalgadget';

	// Abilities:
	Template.Abilities.AddItem('GrapplePowered');

	// Build:
	Template.CanBeBuilt = false;
	Template.StartingItem = true;
	Template.bInfiniteItem = true;
	Template.ArmoryDisplayRequirements.RequiredTechs.AddItem('WraithSuit'); // Won't display in Armoury UI until a Wraith Suit has been "researched" at least once.

	return Template;

}