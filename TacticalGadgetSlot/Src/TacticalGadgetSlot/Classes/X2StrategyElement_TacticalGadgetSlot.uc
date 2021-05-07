class X2StrategyElement_TacticalGadgetSlot extends CHItemSlotSet 
	config (TacticalGadgetSlot);

var config bool bTGS_Log; // Logging

static function array<X2DataTemplate> CreateTemplates() {

	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateTacticalGadgetSlotTemplate());

	return Templates;

}

static function X2DataTemplate CreateTacticalGadgetSlotTemplate() {

	local CHItemSlot Template;

	`CREATE_X2TEMPLATE(class'CHItemSlot', Template, 'TacticalGadget');

	Template.InvSlot = eInvSlot_TacticalGadget;
	Template.SlotCatMask = Template.SLOT_ARMOR | Template.SLOT_ITEM;
	Template.IsUserEquipSlot = true;
	Template.IsEquippedSlot = true;
	Template.BypassesUniqueRule = false;
	Template.IsMultiItemSlot = false;
	// Small slots will be displayed in Squad Select alongside Utility Items/Grenades/Ammo and such.
	// Regular slots won't be displayed in the Vanilla game, but will be a "wide slot" using Robojumper's Squad Select:
	Template.IsSmallSlot = true;

	Template.CanAddItemToSlotFn = CanAddItemToSlot;
	Template.UnitHasSlotFn = UnitHasSlot;
	Template.GetPriorityFn = GetPriority;
	Template.ShowItemInLockerListFn = ShowItemInLockerList;
	Template.ValidateLoadoutFn = ValidateLoadout;
	Template.GetDisplayNameFn = GetDisplayName;

	return Template;

}

static function bool CanAddItemToSlot(CHItemSlot Slot, XComGameState_Unit UnitState, X2ItemTemplate ItemTemplate, optional XComGameState CheckGameState, optional int Quantity = 1, optional XComGameState_Item ItemState) {
	
	local string strDummy;

	if (!Slot.UnitHasSlot(UnitState, strDummy, CheckGameState) || UnitState.GetItemInSlot(Slot.InvSlot, CheckGameState) != none) {
		
		`log(UnitState.GetFullName() @ "cannot add item to" @ Slot.GetDisplayName() @ "Slot:" @ ItemTemplate.FriendlyName @ ItemTemplate.DataName @ ", because unit does not have the" @ Slot.GetDisplayName() @ "Slot:" @ !Slot.UnitHasSlot(UnitState, strDummy, CheckGameState) @ "or" @ "the" @ Slot.GetDisplayName() @ "Slot is already occupied:" @ UnitState.GetItemInSlot(Slot.InvSlot, CheckGameState) != none,default.bTGS_Log,'TacticalGadgetSlot');

		return false;

	}

	if (ItemTemplate.ItemCat == 'TacticalGadget') {

		`log(UnitState.GetFullName() @ "can add item to" @ Slot.GetDisplayName() @ "Slot:" @ ItemTemplate.FriendlyName @ ItemTemplate.DataName @ ", because it has the matching Item Category:" @ ItemTemplate.ItemCat,default.bTGS_Log,'TacticalGadgetSlot');
	
		return true;

	}
}

static function bool UnitHasSlot(CHItemSlot Slot, XComGameState_Unit UnitState, out string LockedReason, optional XComGameState CheckGameState) {  // Add the slot to the appropriate Units

	local XComGameState_Item Armor; // ItemState for checking Armor 

	if (UnitState.IsSoldier() && !UnitState.IsRobotic()) { // Checks if the UnitState is a Soldier and is not a SPARK

		Armor = UnitState.GetItemInSlot(eInvSlot_Armor, CheckGameState); // Gets the currently-equipped Armor from the UnitState

		// Checks if the Unit State has Armor equipped (Failsafe), and if the Armor is either the Corsair or Wraith Suits
		if (Armor != none && Armor.GetMyTemplateName() == 'LightPlatedArmor' || Armor.GetMyTemplateName() == 'LightPoweredArmor') {

			`log(UnitState.GetFullName() @ "has" @ Slot.GetDisplayName() @ "Slot because they are wearing:" @ Armor.GetMyTemplateName(),default.bTGS_Log,'TacticalGadgetSlot');
			
			return true; // Add the slot

		}

	} // Otherwise, don't add the slot

	return false;	

}

static function int GetPriority(CHItemSlot Slot, XComGameState_Unit UnitState, optional XComGameState CheckGameState) {

	return 140;
	 
}

static function bool ShowItemInLockerList(CHItemSlot Slot, XComGameState_Unit UnitState, XComGameState_Item ItemState, X2ItemTemplate ItemTemplate, XComGameState CheckGameState) { // Controls what items can be added to the slot
	
	return ItemTemplate.ItemCat == 'TacticalGadget';

}

static function ValidateLoadout(CHItemSlot Slot, XComGameState_Unit UnitState, XComGameState_HeadquartersXCom XComHQ, XComGameState NewGameState) {
	
	local XComGameState_Item EquippedTacticalGadget;
	local string strDummy;
	local bool HasSlot;
	local XComGameState_Item Armor;

	EquippedTacticalGadget = UnitState.GetItemInSlot(Slot.InvSlot, NewGameState);
	Armor = UnitState.GetItemInSlot(eInvSlot_Armor, NewGameState);
	HasSlot = Slot.UnitHasSlot(UnitState, strDummy, NewGameState);

	`log(UnitState.GetFullName() @ "validating" @ Slot.GetDisplayName() @ "Slot. Unit has slot:" @ HasSlot @ EquippedTacticalGadget == none ? ", slot is empty." : ", slot contains item:" @ EquippedTacticalGadget.GetMyTemplateName(), default.bTGS_Log,'TacticalGadgetSlot');

	if ((EquippedTacticalGadget.GetMyTemplateName() == 'GrapplingHook' && Armor.GetMyTemplateName() == 'LightPoweredArmor')
	|| (EquippedTacticalGadget.GetMyTemplateName() == 'GrapplingHookPowered' && Armor.GetMyTemplateName() == 'LightPlatedArmor')) { // If the Armor and Tactical Gadget configuration is mis-matched, for when the Unit switches between LightPlatedArmor and LightPoweredArmor:

		`log(UnitState.GetFullName() @ "has" @ EquippedTacticalGadget.GetMyTemplateName() @ "equipped on" @ Armor.GetMyTemplateName() @ ". Unequipping the item and putting it into HQ Inventory.", default.bTGS_Log,'TacticalGadgetSlot');
		EquippedTacticalGadget = RemoveGrapplingHook(EquippedTacticalGadget, NewGameState, UnitState, XComHQ);

	}

	if (EquippedTacticalGadget == none && HasSlot) { // If the Unit does NOT have a Tactical Gadget Equipped but DOES have the TacticalGadget slot
		
		// Get Grappling Hook:
		EquippedTacticalGadget = GetGrapplingHook(XComHQ, Armor, NewGameState);
		// Equip Grappling Hook to Unit:
		`log("Equipping" @ EquippedTacticalGadget.GetMyTemplateName() @ "on" @ UnitState.GetFullName(), default.bTGS_Log, 'TacticalGadgetSlot');
		UnitState.AddItemToInventory(EquippedTacticalGadget, eInvSlot_TacticalGadget, NewGameState);
	
	} else if(EquippedTacticalGadget != none && !HasSlot) { // If the Unit DOES have a Tactical Gadget Equipped but does NOT have the TacticalGadget slot

		`log(UnitState.GetFullName() @ "has an item equipped in the" @ Slot.GetDisplayName() @ "Slot, but they do not have the" @ Slot.GetDisplayName() @ "Slot. Unequipping the item and putting it into HQ Inventory.", default.bTGS_Log,'TacticalGadgetSlot');
		EquippedTacticalGadget = RemoveGrapplingHook(EquippedTacticalGadget, NewGameState, UnitState, XComHQ);

	}
}

static function XComGameState_Item RemoveGrapplingHook(XComGameState_Item EquippedTacticalGadget, XComGameState NewGameState, XComGameState_Unit UnitState, XComGameState_HeadquartersXCom XComHQ  ) { // Remove Grappling Hook from Unit:

		EquippedTacticalGadget = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', EquippedTacticalGadget.ObjectID));
		UnitState.RemoveItemFromInventory(EquippedTacticalGadget, NewGameState);
		XComHQ.PutItemInInventory(NewGameState, EquippedTacticalGadget);

		return none;

}

static function XComGameState_Item GetGrapplingHook(XComGameState_HeadquartersXCom XComHQ, XComGameState_Item Armor, XComGameState NewGameState) {
	
	local XComGameStateHistory History;
	local StateObjectReference ItemReference;
	local XComGameState_Item ItemState;

	History = `XCOMHISTORY;

	foreach XComHQ.Inventory(ItemReference) {

		ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemReference.ObjectID));

		if ((Armor.GetMyTemplateName() == 'LightPlatedArmor' && ItemState.GetMyTemplateName() == 'GrapplingHook')
		|| (Armor.GetMyTemplateName() == 'LightPoweredArmor' && ItemState.GetMyTemplateName() == 'GrapplingHookPowered')) {
			
			`log(ItemState.GetMyTemplateName() @ "Item found.", default.bTGS_Log,'TacticalGadgetSlot');
			// Create a new Item State in the NewGameState, since the Template is an infinite item:
			XComHQ.GetItemFromInventory(NewGameState, ItemState.GetReference(), ItemState);

			return ItemState;

		}	 
	}

	return none;

}

static function string GetDisplayName(CHItemSlot Slot) {

	return class'UIArmory_Loadout'.default.m_strInventoryLabels[eInvSlot_TacticalGadget];

}