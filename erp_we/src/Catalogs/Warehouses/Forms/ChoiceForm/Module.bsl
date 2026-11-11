
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	GroupOfWarehouses = Undefined;
	If Parameters.Property("GroupOfWarehouses", GroupOfWarehouses) Then
		CommonClientServer.SetDynamicListFilterItem(List, "Ref", GroupOfWarehouses, DataCompositionComparisonType.InHierarchy,,True);
		Items.List.Representation = TableRepresentation.List;
	EndIf;

	If Parameters.Filter.Property("StartDateOfWarehouseManagemantSystemForGoodsIssue") Then
		StartDateOfWarehouseManagemantSystemForGoodsIssue = Parameters.Filter.StartDateOfWarehouseManagemantSystemForGoodsIssue;
		Parameters.Filter.Delete("StartDateOfWarehouseManagemantSystemForGoodsIssue");
		
		CommonClientServer.SetDynamicListFilterItem(List,
				"StartDateOfWarehouseManagemantSystemForGoodsIssue",
				StartDateOfWarehouseManagemantSystemForGoodsIssue,
				DataCompositionComparisonType.LessOrEqual);
		
	EndIf;
	
	If Parameters.Filter.Property("StartDateOfWarehouseManagemantSystemForGoodsReceipt") Then
		StartDateOfWarehouseManagemantSystemForGoodsReceipt = Parameters.Filter.StartDateOfWarehouseManagemantSystemForGoodsReceipt;
		Parameters.Filter.Delete("StartDateOfWarehouseManagemantSystemForGoodsReceipt");
		
		CommonClientServer.SetDynamicListFilterItem(List,
				"StartDateOfWarehouseManagemantSystemForGoodsReceipt",
				StartDateOfWarehouseManagemantSystemForGoodsReceipt,
				DataCompositionComparisonType.LessOrEqual);
		
	EndIf;
	
	If Parameters.Filter.Property("StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages") Then
		StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages = Parameters.Filter.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages;
		Parameters.Filter.Delete("StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages");
		
		CommonClientServer.SetDynamicListFilterItem(List,
				"StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages",
				StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages,
				DataCompositionComparisonType.LessOrEqual);
		
	EndIf;
	
	If Parameters.Filter.Property("CustodyWarehouse") Then
		CustodyWarehouse = Parameters.Filter.CustodyWarehouse;
		Parameters.Filter.Delete("CustodyWarehouse");
		
		CommonClientServer.SetDynamicListFilterItem(List,
				"CustodyWarehouse",
				CustodyWarehouse,
				DataCompositionComparisonType.Equal);
		
	EndIf;
	
	If Parameters.Property("LinkIsNotInList") Then
		CommonClientServer.SetDynamicListFilterItem(List, "Ref", Parameters.LinkIsNotInList, DataCompositionComparisonType.NotInList, "LinkIsNotInList", True);
	EndIf;
	
	SelectWarehouseGroup = Undefined;
	
	ProhibitChangingCompositionOfStrings = False;
	If Not Parameters.Property("SelectWarehouseGroup", SelectWarehouseGroup) Or
		(Not GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments") And Parameters.Property("DocumentSales"))
		Or (Not GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments") And Parameters.Property("DocumentPurchases")) Then
		
		FilterArray = New Array();
		FilterArray.Add(Enums.SelectWarehouseGroup.Disable);
		FilterArray.Add(Enums.SelectWarehouseGroup.AllowInOrders);
		FilterArray.Add(Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices);
		SelectWarehouseGroup = New FixedArray(FilterArray);
		ProhibitChangingCompositionOfStrings = True;
		
	EndIf;
	
	List.Parameters.SetParameterValue("SelectWarehouseGroup", SelectWarehouseGroup);
	
	Items.List.ChangeRowSet = 
		GetFunctionalOption("UseSeveralWarehouses") And Not ProhibitChangingCompositionOfStrings;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
	If ValueIsFilled(SelectWarehouseGroup) And ValueIsFilled(Value) And Items.List.CurrentData <> Undefined Then
		
		CurrentData = Items.List.CurrentData;
		SelectionIsForbidden = CurrentData.IsFolder;
		
		If SelectionIsForbidden Then
			If TypeOf(SelectWarehouseGroup) = Type("FixedArray") Then
				For Each CurItem In SelectWarehouseGroup Do
					If CurItem = CurrentData.SelectGroup Then
						SelectionIsForbidden = False;
						Break;
					EndIf;
				EndDo;
			Else
				If SelectWarehouseGroup = CurrentData.SelectGroup Then
					SelectionIsForbidden = False;
				EndIf;
			EndIf;
		EndIf;
		
		If SelectionIsForbidden Then
			
			StandardProcessing = False;
			Cancel = True;
			WarningText = NStr("vi = 'Không nên chọn nhóm ""%GroupOfWarehouses%"" vào chứng từ.';
								|ru = 'Группу ""%GroupOfWarehouses%"" нельзя выбирать в документ.';
								|en = 'Group ""%GroupOfWarehouses%"" cannot be selected for the document.'; fa = 'Group ""%GroupOfWarehouses%"" cannot be selected for the document.';
								|it = 'Non è possibile selezionare il gruppo ""%GroupOfWarehouses%"" nel documento.';
								|pl = 'Grupa ""%GroupOfWarehouses%"" nie może zostać wybrana do dokumentu.';
								|tr = 'Belgede ""%GroupOfWarehouses%"" grubu seçilemez.'");
			WarningText = StrReplace(WarningText, "%GroupOfWarehouses%", CurrentData.Description);
			ShowMessageBox(Undefined, WarningText);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

