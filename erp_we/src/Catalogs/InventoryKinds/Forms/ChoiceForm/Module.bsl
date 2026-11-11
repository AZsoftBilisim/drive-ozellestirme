
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("Filter") Then
		
		If Parameters.Filter.Property("BusinessOperation") Then
			If Parameters.Filter.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
			 Or Parameters.Filter.BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany Then
				Parameters.Filter.Insert("InventoryType", Enums.InventoryTypes.ConsignedGoods);
			Else
				Parameters.Filter.Insert("InventoryType", Enums.InventoryTypes.OwnGoods);
			EndIf;
		EndIf;
		
		If Parameters.Filter.Property("BusinessOperation") Then
			If Parameters.Filter.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse Then
				Parameters.Filter.Insert("InventoryType", Enums.InventoryTypes.ConsignedGoods);
			ElsIf Parameters.Filter.BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting Then
				Parameters.Filter.Insert("InventoryType", Enums.InventoryTypes.MaterialOfMaterialProvider);
			ElsIf Parameters.Filter.BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider Then
				Parameters.Filter.Insert("InventoryType", Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
			ElsIf Parameters.Filter.BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
				Parameters.Filter.Insert("InventoryType", Enums.InventoryTypes.ProductsOfMaterialProvider);
			Else
				Parameters.Filter.Insert("InventoryType", Enums.InventoryTypes.OwnGoods);
			EndIf;
		EndIf;
		
		If Parameters.Filter.Property("Products") Then
			FinancialAccountingGroup = TMCommonUse.DefaultValuesForItemDetails(Parameters.Filter.Products,
																	"FinancialAccountingGroup").FinancialAccountingGroup;
			GroupsArray1 = New Array;
			GroupsArray1.Add(FinancialAccountingGroup);
			GroupsArray1.Add(Catalogs.InventoryAccountingGroups.EmptyRef());
			Parameters.Filter.Insert("FinancialAccountingGroup", GroupsArray1);
		EndIf;
		
	EndIf;

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

