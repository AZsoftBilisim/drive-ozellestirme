
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	AllowEditingAddressStorageSettings                             = True;
	AllowEditingToUseTheOrderSchemeWhenShipping                   = True;
	AllowEditingToUseTheOrderSchemeOnReceipt                = True;
	AllowEditingToUseStorageSpaces                         = True;
	AllowEditingToUseTheOrderSchemeWhenRegisteringSurplusesAndShortfalls = True;
	AllowEditingWarehouseType                                              = True;
	AllowEditingParent                                               = True;
	AllowEditingRetailPriceView                                       = True;
	AllowEditingIndividualPriceView                                  = True;
	AllowUsingTheStatusesOfIncomingOrders                                  = True;
	ToAllowTheUseStatusesOfConsumableOrders                                  = True;
	AllowEditingTheStartDateOfTheOrderSchemeDuringShipment                     = True;
	AllowEditingTheStartDateOfTheOrderSchemeOnReceipt                  = True;
	AllowEditingTheStartDateOfTheOrderSchemeWhenReflectingSurplusesShortfalls    = True;
	AllowEditingStartDateOfStorageSpaceUsage              = True;
	AllowEditingStartDateOfAddressStorageOfBalances                    = True;
	AllowEditingOfTheWorkshopStoreroom                                        = True;
	AllowDivisionEditing                                          = True;
	AllowQualityControlEditing                                       = True;
	
	ItemArray = New Array;
	ItemArray.Add("AllowEditingWarehouseType");
	ItemArray.Add("AllowEditingRetailPriceView");
	ItemArray.Add("AllowEditingIndividualPriceView");
	ItemArray.Add("DescriptionWarehouseType");
	ItemArray.Add("DescriptionRetailPriceType");
	ItemArray.Add("DescriptionIndividualTypeOfPrices");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		ItemArray,
		"Visible",
		GetFunctionalOption("UseRetailSales"));
		
	TMCommonUseClientServer.SetPropertyOfFormElements(Items,
		"AllowQualityControlEditing,
		|DescriptionQualityControl",
		"Visible",
		GetFunctionalOption("UseGoodsQualityControl"));
		
	UseWarehouseManagementSystem = GetFunctionalOption("UseWarehouseManagementSystem");
	For Each Item In Items.GroupDependentOnTheOrderScheme.ChildItems Do
		Item.Visible = UseWarehouseManagementSystem;
	EndDo;

	If Not GetFunctionalOption("EnterpriseManagement") Then
		Items.DescriptionShopStoreroom.Visible = False;
	ElsIf Not GetFunctionalOption("UseProductionManagement2_2") Then
		Items.DescriptionShopStoreroom.Visible = False;
		Items.AllowEditingOfTheGuildStorage.Visible = False;
	EndIf; 
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region Other

&AtClient
Procedure EnableEdit(Command)

	Result = New Array;
	If AllowEditingToUseTheOrderSchemeWhenShipping Then
		Result.Add("UseWarehouseManagemantSystemForGoodsIssue");
	EndIf;

	If AllowEditingToUseTheOrderSchemeOnReceipt Then
		Result.Add("UseWarehouseManagemantSystemForGoodsReceipt");
	EndIf;
	
	If AllowEditingToUseStorageSpaces Then
		Result.Add("UseWarerooms");
	EndIf;
	
	If AllowEditingAddressStorageSettings Then
		Result.Add("CustomizeBinLocationWarehousing");
	EndIf;

	If AllowEditingToUseTheOrderSchemeWhenRegisteringSurplusesAndShortfalls Then
		Result.Add("UseWarehouseManagemantSystemForGoodsSurplusesShortages");
	EndIf;
	
	If AllowEditingWarehouseType Then
		Result.Add("WarehouseStore");
	EndIf;
	
	If AllowEditingParent Then
		Result.Add("Parent");
	EndIf;
	
	If AllowUsingTheStatusesOfIncomingOrders Then
		Result.Add("UseGoodsReceiptNoteStatuses");
	EndIf;
	
	If ToAllowTheUseStatusesOfConsumableOrders Then
		Result.Add("UseGoodsIssueNoteStatuses");
	EndIf;
	
	If AllowEditingRetailPriceView Then
		Result.Add("RetailPriceType");
	EndIf;
	
	If AllowEditingIndividualPriceView Then
		Result.Add("SpecialPriceType");
	EndIf;
	
	If AllowEditingTheStartDateOfTheOrderSchemeDuringShipment Then
		Result.Add("StartDateOfWarehouseManagemantSystemForGoodsIssue");
	EndIf;
	
	If AllowEditingTheStartDateOfTheOrderSchemeOnReceipt Then
		Result.Add("StartDateOfWarehouseManagemantSystemForGoodsReceipt");
	EndIf;
	
	If AllowEditingTheStartDateOfTheOrderSchemeWhenReflectingSurplusesShortfalls Then
		Result.Add("StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages");
	EndIf;
	
	If AllowEditingStartDateOfStorageSpaceUsage Then
		Result.Add("StartDateOfWareroomUse");
	EndIf;
	
	If AllowEditingStartDateOfAddressStorageOfBalances Then
		Result.Add("StartDateOfUsingWarehouseBinSystem");
	EndIf;
	If AllowEditingOfTheWorkshopStoreroom Then
		Result.Add("ShopFloorStockroom");
	EndIf;
	If AllowDivisionEditing Then
		Result.Add("Department");
	EndIf;
	
	If AllowQualityControlEditing Then
		Result.Add("ControlQualityOfReceivedGoods");
	EndIf;
	
	Close(Result);

EndProcedure

#EndRegion

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
