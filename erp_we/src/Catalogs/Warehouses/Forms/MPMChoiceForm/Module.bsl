#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	GroupOfWarehouses = Undefined;
	If Parameters.Property("GroupOfWarehouses", GroupOfWarehouses) Then    
		
		FilterElement = List.SettingsComposer.FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue = New DataCompositionField("Ref");
		FilterElement.ComparisonType = DataCompositionComparisonType.InHierarchy;
		FilterElement.RightValue = GroupOfWarehouses;

		Items.List.Representation = TableRepresentation.List;
	EndIf;

	SelectWarehouseGroup = Undefined;
	Parameters.Property("SelectWarehouseGroup", SelectWarehouseGroup);	
	List.Parameters.SetParameterValue("SelectWarehouseGroup", SelectWarehouseGroup);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
	If ValueIsFilled(SelectWarehouseGroup) And ValueIsFilled(Value) 
		And Items.List.CurrentData <> Undefined Then
		
		CurrentData = Items.List.CurrentData;
		SelectionIsForbidden = CurrentData.IsFolder;
		
		If SelectionIsForbidden Then
			If TypeOf(SelectWarehouseGroup) = Type("FixedArray") Then
				SelectionIsForbidden = Not (SelectWarehouseGroup.Find(CurrentData.SelectGroup) <> Undefined);
			Else
				SelectionIsForbidden = SelectWarehouseGroup <> CurrentData.SelectGroup;
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
#EndRegion
