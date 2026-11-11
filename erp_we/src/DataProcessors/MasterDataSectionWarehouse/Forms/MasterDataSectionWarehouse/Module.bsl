
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ManagingElements();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure DiscoverWaysToMeetYourNeeds(Command)
	
	OpenForm("Catalog.ProcurementStrategies.ListForm", , ThisObject);
	
EndProcedure

&AtClient
Procedure OpenSecuritySchemes(Command)
	
	OpenForm("Catalog.SupplySchemes.ListForm", , ThisObject);
	
EndProcedure

&AtClient
Procedure OpenDeliveryZones(Command)
	
	OpenForm("Catalog.DeliveryZones.ListForm", , ThisObject);
	
EndProcedure

&AtClient
Procedure OpenVehicleTypes(Command)

	OpenForm("Catalog.VehicleTypes.ListForm", , ThisObject);
	
EndProcedure

&AtClient
Procedure OpenPlacementRules(Command)

	OpenForm("InformationRegister.GoodsPlacementRules.ListForm", , ThisObject);
	
EndProcedure

&AtClient
Procedure ToOpenTheSizesOfCells(Command)

	OpenForm("Catalog.StandardSizesOfStorageBins.ListForm", , ThisObject);
	
EndProcedure

&AtClient
Procedure AccessToForecastsOfTheConsumptionOfPackaging(Command)
	
	OpenForm("InformationRegister.PackageConsumptionForecasts.ListForm", , ThisObject);
	
EndProcedure

&AtClient
Procedure OpenReasonsForBlockingGoods(Command)
	
	OpenForm("Catalog.GoodsLockReasons.ListForm", , ThisObject);
	
EndProcedure

&AtClient
Procedure OpenGoodsResearchCards(Command)
	OpenForm("Catalog.GoodsResearchSheets.ListForm", , ThisObject);
	Return;
	
EndProcedure

&AtClient
Procedure Attachable_OnExecuteCommand(Command)
	
	WarehousesClientLocalization.WhenExecuting_CommandWarehouseReferencePanel(Command, ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ManagingElements()
	
	DeliveryZoneAccessRights 				= AccessRight("View", Metadata.Catalogs.DeliveryZones);
	RightOfAccessVehicleTypes 	= AccessRight("View", Metadata.Catalogs.VehicleTypes);
	AccessRightsPlacementRules 			= AccessRight("View", Metadata.InformationRegisters.GoodsPlacementRules);
	RightOfAccessStandardSizesOfCells 			= AccessRight("View", Metadata.Catalogs.StandardSizesOfStorageBins);
	RightOfAccessForecastsOfConsumptionOfPackages 	= AccessRight("View", Metadata.InformationRegisters.PackageConsumptionForecasts);
	RightOfAccessWaysToMeetNeeds = AccessRight("Update", Metadata.Catalogs.ProcurementStrategies);
	SecuritySchemeAccessRights               = AccessRight("Update", Metadata.InformationRegisters.SupplySchemes);
	RightOfAccessReasonsForBlockingGoods = AccessRight("View", Metadata.Catalogs.GoodsLockReasons);
	GoodsResearchCardAccessRight = AccessRight("View", Metadata.Catalogs.GoodsResearchSheets);
	CommonClientServer.SetFormItemProperty(Items,
		"OpenDeliveryZones",
		"Visible",
		DeliveryZoneAccessRights);
	CommonClientServer.SetFormItemProperty(Items,
		"OpenVehicleTypes",
		"Visible",
		RightOfAccessVehicleTypes);
	CommonClientServer.SetFormItemProperty(Items,
		"OpenPlacementRules",
		"Visible",
		AccessRightsPlacementRules);
	CommonClientServer.SetFormItemProperty(Items,
		"ToOpenTheSizesOfCells",
		"Visible",
		RightOfAccessStandardSizesOfCells);
	CommonClientServer.SetFormItemProperty(Items,
		"AccessToForecastsOfTheConsumptionOfPackaging",
		"Visible",
		RightOfAccessForecastsOfConsumptionOfPackages);
	CommonClientServer.SetFormItemProperty(Items,
		"DiscoverWaysToMeetYourNeeds",
		"Visible",
		RightOfAccessWaysToMeetNeeds);
	CommonClientServer.SetFormItemProperty(Items,
		"OpenSecuritySchemes",
		"Visible",
		SecuritySchemeAccessRights);
	CommonClientServer.SetFormItemProperty(Items,
		"OpenReasonsForBlockingGoods",
		"Visible",
		RightOfAccessReasonsForBlockingGoods);
	CommonClientServer.SetFormItemProperty(Items,
		"OpenGoodsResearchCards",
		"Visible",
		GoodsResearchCardAccessRight);
	ThereIsDataToDisplay =
		GetFunctionalOption("UseItemPackages")
		Or GetFunctionalOption("UseDeliveryManagement")
		Or GetFunctionalOption("UseBinLocationWarehousing")
		Or GetFunctionalOption("UseInventoryConsumption")
		Or GetFunctionalOption("UseAdvancedDemandFulfillment")
		Or DeliveryZoneAccessRights
		Or RightOfAccessVehicleTypes
		Or AccessRightsPlacementRules
		Or RightOfAccessStandardSizesOfCells
		Or RightOfAccessForecastsOfConsumptionOfPackages
		Or GoodsResearchCardAccessRight
		Or RightOfAccessReasonsForBlockingGoods;
		
	WarehousesLocalization.ItemManagement_CatalogPanel_(Items, ThereIsDataToDisplay);
		
	Items.GroupTheNecessarySettingsAreNotSet.Visible = Not ThereIsDataToDisplay;
	
EndProcedure

#EndRegion