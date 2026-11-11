
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	FormItemsManagement();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Currency.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.InventoryType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.InventoryTypes.ConsignedGoods;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Currency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsOwner.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.InventoryType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.InventoryTypes.ConsignedGoods);
	ValueList.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GoodsOwner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BusinessUnitProduction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SubjectToExcise");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessUnitProduction");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
EndProcedure

#Region FormItemsManagement

&AtServer
Procedure FormItemsManagement()
	
	ThisIsCommissionItem	= Object.InventoryType = Enums.InventoryTypes.ConsignedGoods;
	ThisIsAnswerStorage		= Object.InventoryType = Enums.InventoryTypes.GoodsInStorageWithRightToSell;
	ThisIsTransferToCommission	= Object.GoodsTransferMethod = Enums.GoodsTransferMethods.TransferToCommissionAgent;
	
	Items.GoodsOwner.Visible		= ThisIsCommissionItem
												Or ThisIsTransferToCommission
												Or ThisIsAnswerStorage;
	Items.Counterparty.Visible			= ValueIsFilled(Object.Counterparty)
												Or ThisIsCommissionItem
												Or ThisIsTransferToCommission
												Or ThisIsAnswerStorage;
	Items.Terms.Visible			= ThisIsCommissionItem
												Or ThisIsAnswerStorage;
	Items.Contract.Visible				= ThisIsCommissionItem
												Or ThisIsAnswerStorage;
	Items.Currency.Visible				= ThisIsCommissionItem
												Or ThisIsTransferToCommission
												Or ThisIsAnswerStorage;
	Items.PriceKind.Visible				= ThisIsAnswerStorage;
	Items.ProductsGroup.Visible		= False;
	Items.GroupExciseTaxData.Visible	= False;
	Items.ProductsGroup.Visible		= GetFunctionalOption("AnalyticalAccountingByProductsGroups");
	Items.GroupExciseTaxData.Visible	= GetFunctionalOption("UseExcisableGoods");
	TypesOfGiverSInventory = New Array;
	TypesOfGiverSInventory.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
	TypesOfGiverSInventory.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
	TypesOfGiverSInventory.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
	
	If TypesOfGiverSInventory.Find(Object.InventoryType) <> Undefined Then
		Items.GoodsOwner.Visible	= True;
		Items.Counterparty.Visible		= True;
		Items.Contract.Visible			= True;
	EndIf;
EndProcedure

#EndRegion

#EndRegion
