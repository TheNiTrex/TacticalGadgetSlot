//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_TacticalGadgetSlot.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_TacticalGadgetSlot extends X2DownloadableContentInfo;

var localized string m_strIncompatible;
var localized string m_strObsolete;

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame() {}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed
/// </summary>
static event InstallNewCampaign(XComGameState StartState) {}

static event OnPostTemplatesCreated() {

	// Remove Grapple Ability:
	RemoveGrappleAbility();

}

// ################################################
// ###-REMOVE-GRAPPLE-ABILITY-FROM-LIGHT-ARMORS-###
// ################################################

static function RemoveGrappleAbility() { // OPTC to get the template of it X2ArmorTemplate 'LightPlatedArmor', then do a Template.Abilities.RemoveItem('Grapple');

	local X2ItemTemplateManager TemplateManager; // Create Item Manager to access Armor Templates
	local array<name> ArmorTemplateNames;
	local name ArmorTemplateName;
	local X2ArmorTemplate ArmorTemplate;

	// Access Item Template Manager:
	TemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager(); 

	// Add Weapon Template Names to list:
	ArmorTemplateNames.AddItem('LightPlatedArmor');
	ArmorTemplateNames.AddItem('LightPoweredArmor');
	
	// Iterate through list:
	foreach ArmorTemplateNames(ArmorTemplateName) {
		
		// Modify Weapon Template:
		ArmorTemplate = X2ArmorTemplate(TemplateManager.FindItemTemplate(ArmorTemplateName));
		if (ArmorTemplateName == 'LightPlatedArmor') ArmorTemplate.Abilities.RemoveItem('Grapple');
		if (ArmorTemplateName == 'LightPoweredArmor') ArmorTemplate.Abilities.RemoveItem('GrapplePowered');

	}
}

// ####################################
// ###-TACTICAL-GADGET-RESTRICTIONS-###
// ####################################

static function bool CanAddItemToInventory_CH_Improved(
    out int	bCanAddItem, // out value for XComGameState_Unit
    const EInventorySlot Slot, // Inventory Slot you're trying to equip the Item into
    const X2ItemTemplate ItemTemplate, // Item Template of the Item you're trying to equip
    int	Quantity, 
    XComGameState_Unit UnitState, // Unit State of the Unit you're trying to equip the Item on
    optional XComGameState CheckGameState, 
    optional out string	DisabledReason, // out value for the UIArmory_Loadout
    optional XComGameState_Item	ItemState) { // Item State of the Item we're trying to equip

    local bool OverrideNormalBehavior;
    local bool DoNotOverrideNormalBehavior;
	local XGParamTag LocTag;

	local XComGameState_Item Armor; // ItemState for checking Armor 
	local CHItemSlotStore TemplateManager; // For fetching the TacticalGadget Slot
	local CHItemSlot CHItemSlot;

    // Prepare return values to make it easier to read the code:
    OverrideNormalBehavior = CheckGameState != none;
    DoNotOverrideNormalBehavior = CheckGameState == none;

    // If there already is a Disabled Reason, it means another mod has already disallowed equipping this item.
    // In this case, we do not interfere with that mod's functions for better compatibility:
    if (DisabledReason != "") 
	{
        return DoNotOverrideNormalBehavior;

	}

	Armor = UnitState.GetItemInSlot(eInvSlot_Armor, CheckGameState);

	if ((ItemTemplate.DataName == 'GrapplingHookPowered' && Armor.GetMyTemplateName() == 'LightPlatedArmor') 
	|| (ItemTemplate.DataName == 'GrapplingHook' && Armor.GetMyTemplateName() == 'LightPoweredArmor')) { // Bar invalid Armor and Tactical Gadget configurations:

		TemplateManager = class'CHItemSlotStore'.static.GetStore();
		CHItemSlot = TemplateManager.GetSlot(eInvSlot_TacticalGadget);

		LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		LocTag.StrValue0 = "";
		// Build a custom DisabledReason message using localized strings and the custom slot's GetDisplayNameFn:
		if (ItemTemplate.DataName == 'GrapplingHook') DisabledReason = default.m_strObsolete @ class'X2StrategyElement_TacticalGadgetSlot'.static.GetDisplayName(CHItemSlot);
		if (ItemTemplate.DataName == 'GrapplingHookPowered') DisabledReason = default.m_strIncompatible @ class'X2StrategyElement_TacticalGadgetSlot'.static.GetDisplayName(CHItemSlot);
		bCanAddItem = 0;

		return OverrideNormalBehavior;

	}

	return DoNotOverrideNormalBehavior;

}