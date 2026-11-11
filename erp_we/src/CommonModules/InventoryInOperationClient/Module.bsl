////////////////////////////////////////////////////////////////////////////////
// Procedures and functions of the TMC subsystem in operation.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// 
// Parameters:
//  CurrentRow - Structure - 
//  StructureOfActions - Structure - 
//  CachedValues - Structure - 
// 
// Returns:
//  Boolean -
Function ServerCallIsRequiredToProcessTSString(CurrentRow, StructureOfActions, CachedValues) Export
	
	If StructureOfActions.Property("FillInCategoryAttributes") Then
		If ValueIsFilled(CurrentRow.OperationCategory)
			And CachedValues.SignsOfCategoryOfOperation.Get(CurrentRow.OperationCategory) = Undefined Then
			Return True;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

// See BatchProcessingOfTablePartClient.ProcessTSString
Procedure ProcessTSString(CurrentRow, StructureOfActions, CachedValues, AdditionalFillingParameters = Undefined) Export
	
	FillInCategoryAttributes(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

// Processes the line when the category of operation changes.
// 
// Parameters:
//  RowData - FormDataStructure, Array of FormDataStructure - Current line.
//  TabularSection - FormDataCollection - The tabular part.
//  StructureOfActions - Structure - Structure of actions.
//	QuantityField - String - The "Quantity" field.
Procedure ProcessLineWhenChangingCategoryOfOperation(RowData, TabularSection, StructureOfActions = Undefined, QuantityField = "") Export
	
	If QuantityField = "" Then
		QuantityField = "NumberOfPackages";
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("RowData", RowData);
	AdditionalParameters.Insert("TabularSection", TabularSection);
	AdditionalParameters.Insert("StructureOfActions", StructureOfActions);
	AdditionalParameters.Insert("QuantityField", QuantityField);

	If TypeOf(RowData) = Type("Array") Then
		
		ItIsRequiredToSplitLines = False;
		
		For Each LineID In RowData Do
			CurrentRow = TabularSection.FindByID(LineID);
		 	If ValueIsFilled(CurrentRow.OperationCategory) 
				And CurrentRow.StocktakingRecord
				And CurrentRow[QuantityField] > 1 Then
		 		ItIsRequiredToSplitLines = True;
		 		Break
		 	EndIf;
		EndDo;
		
	Else
		
		ItIsRequiredToSplitLines = 
			ValueIsFilled(RowData.OperationCategory) 
			And RowData.StocktakingRecord
			And RowData[QuantityField] > 1;
			
	EndIf;
	
	If ItIsRequiredToSplitLines Then

		If TypeOf(RowData) = Type("Array")
			And RowData.Count() > 1 Then
			
			QueryText = NStr("vi = 'Trong thể loại sử dụng có bật kế toán kiểm kê, số lượng phải bằng 1.
								|Tách dòng hoặc đặt số lượng bằng 1?';
								|ru = 'В категории эксплуатации включен инвентарный учет, количество должно быть равным 1.
								|Разбить строки или установить количество равным 1?';
								|en = 'The inventory accounting is enabled in the operation category, the quantity must be equal to 1.
								|Do you want to split the lines or set the quantity to 1?'; fa = 'The inventory accounting is enabled in the operation category, the quantity must be equal to 1.
								|Do you want to split the lines or set the quantity to 1?';
								|it = 'Nella categoria di lavorazione è attivata la contabilità di inventario, la quantità deve essere pari a 1.
								|Dividere le stringhe oppure impostare la quantità pari a 1?';
								|pl = 'W kategorii eksploatacji jest włączona ewidencja inwentarzowa, ilość powinna być równa 1.
								|Podzielić wiersze lub ustawić ilość na 1?';
								|tr = 'Stok işlem kategorisine dahil edilir, miktar 1''e eşit olmalıdır. 
								|Satırlar bölünsün mü yoksa sayıyı 1 olarak ayarlanasın mı?'");
								
			ButtonText = NStr("vi = 'Tách dòng';
								|ru = 'Разбить строки';
								|en = 'Split lines'; fa = 'Split lines';
								|it = 'Dividere stringhe';
								|pl = 'Podziel wiersze';
								|tr = 'Satırları bölme'");
			
		Else
			
			QueryText = NStr("vi = 'Trong thể loại sử dụng có bật kế toán kiểm kê, số lượng phải bằng 1.
								|Tách dòng hoặc đặt số lượng bằng 1?';
								|ru = 'В категории эксплуатации включен инвентарный учет, количество должно быть равным 1.
								|Разбить строку или установить количество равным 1?';
								|en = 'The inventory accounting is enabled in the operation category, the quantity must equal 1.
								|Do you want to split the line or set the quantity to 1?'; fa = 'The inventory accounting is enabled in the operation category, the quantity must equal 1.
								|Do you want to split the line or set the quantity to 1?';
								|it = 'Nella categoria di lavorazione è attivata la contabilità di inventario, la quantià deve essere pari a 1.
								|Dividere la riga oppure impostare la quantità pari a 1?';
								|pl = 'W kategorii eksploatacji jest włączona ewidencja inwentarzowa, ilość powinna być równa 1.
								|Podzielić wiersz lub ustawić ilość na 1?';
								|tr = 'Stok işlem kategorisine dahil edilir, miktar 1''e eşit olmalıdır. 
								|Satırlar bölünsün mü yoksa sayıyı 1 olarak ayarlanasın mı?'");
								
			ButtonText = NStr("vi = 'Tách dòng';
								|ru = 'Разбить строку';
								|en = 'Split line'; fa = 'تفکیک سطر';
								|it = 'Dividi la riga';
								|pl = 'Podziel wiersz';
								|tr = 'Satırı böl'");
			
		EndIf;
		
		CallbackDescription = New CallbackDescription("ProcessLineWhenChangingCategoryOfOperationCompletion", ThisObject, AdditionalParameters);
		
		ButtonsList = New ValueList();
		ButtonsList.Add(DialogReturnCode.Yes, ButtonText);
		ButtonsList.Add(DialogReturnCode.No, NStr("vi = 'Thay đổi số lượng';
													|ru = 'Изменить количество';
													|en = 'Change quantity'; fa = 'تغییر مقدار';
													|it = 'Cambiare quantità';
													|pl = 'Zmień ilość';
													|tr = 'Miktarı değiştir'"));
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
		
	Else
		
		ProcessLineWhenChangingCategoryOfOperationCompletion(DialogReturnCode.No, AdditionalParameters);
		
	EndIf;
	
EndProcedure

// 
// Parameters:
//  StructureOfTSFields - Structure - Structure of TS fields
//  CurrentRow - Structure - Current line
//  StructureOfActions - Structure - structure of actions
//  AdditionalFillingParameters - Structure - Additional Filling Parameters
Procedure AddCurLineWithStructure(StructureOfTSFields, CurrentRow, StructureOfActions, AdditionalFillingParameters) Export
	
	If StructureOfActions.Property("FillInCategoryAttributes") Then
		StructureOfTSFields.Insert("OperationCategory");
		StructureOfTSFields.Insert("StocktakingRecord");
		StructureOfTSFields.Insert("AccountingForIndividuals");
		StructureOfTSFields.Insert("AccountAsGroupFA");
		StructureOfTSFields.Insert("MethodOfRepaymentOfCostOfAC");
		StructureOfTSFields.Insert("ExpenseItem");
		StructureOfTSFields.Insert("ServiceLife");
	EndIf;
	
EndProcedure

// Handler for the command to fill in the category of operation in the selected rows of the table.
// 
// Parameters:
// 	TabularSection - FormDataCollection - The tabular part.
// 	SelectedRows - Array of Number - Selected rows of the form table.
// 	ChoiceParameters - Structure - selection parameters.
// 	DescriptionOfNotificationAfterFillingIn - CallbackDescription - Descriptions of the notification to be called after filling in.
//
Procedure FillInCategoryOfOperation(TabularSection, SelectedRows, ChoiceParameters = Undefined, DescriptionOfNotificationAfterFillingIn = Undefined) Export
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("TabularSection", TabularSection);
	AdditionalParameters.Insert("SelectedRows", SelectedRows);
	AdditionalParameters.Insert("DescriptionOfNotificationAfterFillingIn", DescriptionOfNotificationAfterFillingIn);
	CallbackDescription = New CallbackDescription("FillInCategoryOfOperationCompletion", ThisObject, AdditionalParameters);
	
	OpenForm("Catalog.OperationCategories.ChoiceForm", ChoiceParameters,,,,, CallbackDescription);
	
EndProcedure

// Fills in the selection list when auto-selecting by inventory number.
// 
// Parameters:
//  Text - String - Input text.
//  PickingParameters - See InventoryInOperationClientServer.ParametersOfSelectionOfGoodsInOperation
//  ChoiceData - ValueList - Selection data.
//  StandardProcessing - Boolean - indicates standard event handling.
//
Procedure AutoSelectionByInventoryNumber(Text, PickingParameters, ChoiceData, StandardProcessing) Export
	
	If Not ValueIsFilled(Text) Then
		Return;
	EndIf;
	
	PerformanceMonitorClient.TimeMeasurement("InventoryInOperationClient.AutoSelectionByInventoryNumber");
	
	If PickingParameters = Undefined Then
		PickingParameters = InventoryInOperationClientServer.ParametersOfSelectionOfGoodsInOperation();
	EndIf;
	
	PickingParameters.InventoryNumberContains = Text;
	PickingParameters.SelectFirstRecords = 10;
	
	StandardProcessing = False;
	
	ChoiceData = New ValueList;
	
	InventoryInOperationServerCall.FillInSelectionDataByInventoryNumber(
		PickingParameters, 
		ChoiceData);
	
EndProcedure

// Retrieves the print data and opens the label printing form.
//
// Parameters:
//	CommandDetails - Structure - structure with a description of the Command:
//	                    * Id - String - Can take the values of "Labels";
//	                    * PrintObjects - Array - print objects.
//
// Returns:
//	Undefined - Returns nothing.
//
Function PrintingOfTMTSVOperationLabelsFromDocument(CommandDetails) Export
	
	PrintParameters = New Structure;
	PrintParameters.Insert("Id", CommandDetails.Id);
	PrintParameters.Insert("PrintObjects", CommandDetails.PrintObjects);
	PrintParameters.Insert("AdditionalParameters", New Structure("PrintManager", CommandDetails.PrintManager));
	
	FormParameters = New Structure;
	FormParameters.Insert("PrintFromDocument", PrintParameters);
	
	OpenForm(
		"DataProcessor.PrintLabelsOfInventoryInOperation.Form",
		FormParameters,
		CommandDetails.Form,
		New UUID);
	
	Return Undefined;
	
EndFunction

// Handler for the fill-in command phys. the faces of the selected rows of the table.
// 
// Parameters:
// 	TabularSection - FormDataCollection - The tabular part.
// 	SelectedRows - Array of Number - Selected rows of the form table.
// 	FieldName_Individual - String - The name of the field containing the individual.
//
Procedure FillInIndividual(TabularSection, SelectedRows, FieldName_Individual = "Individual") Export
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("TabularSection", TabularSection);
	AdditionalParameters.Insert("SelectedRows", SelectedRows);
	AdditionalParameters.Insert("FieldName_Individual", FieldName_Individual);
	CallbackDescription = New CallbackDescription("FillInIndividualCompletion", ThisObject, AdditionalParameters);
	
	PickingParameters = New Structure;
	PickingParameters.Insert("ChoiceMode", True);
	PickingParameters.Insert("CloseOnChoice", True);
	PickingParameters.Insert("MultipleChoice", False);

	OpenForm("Catalog.Persons.ChoiceForm", PickingParameters,,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

// opens the door to the Inventory in operation.
// 
// Parameters:
//  FormParameters - Structure - Shape parameter
//	Form - ClientApplicationForm - Form
Procedure SelectTheTmtsvexploitation(FormParameters, Form) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.OtherGoodsRecordingAsReceived.DocumentForm.Command.SelectTheTmtsvexploitation");
	
	FormName = "Catalog.LotsOfInventoryInOperation.Form.PickFormTM";
	FormName = "Catalog.LotsOfInventoryInOperation.Form.PickForm";
	OpenForm(FormName, FormParameters, Form);
	
EndProcedure

Procedure FillInCategoryAttributes(CurrentRow, StructureOfActions, CachedValues)
	
	If Not StructureOfActions.Property("FillInCategoryAttributes") Then
		Return;
	EndIf;
		
	FeatureStructure = CachedValues.SignsOfCategoryOfOperation.Get(
		CurrentRow.OperationCategory);
		
	If FeatureStructure <> Undefined Then
		FillPropertyValues(CurrentRow, FeatureStructure);
	EndIf;
	
EndProcedure

Procedure ProcessLineWhenChangingCategoryOfOperationCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes 
		And QuestionResult <> DialogReturnCode.No Then
		Return;
	EndIf;

	RowData = AdditionalParameters.RowData;
	TabularSection = AdditionalParameters.TabularSection; // TabularSection
	QuantityField = AdditionalParameters.QuantityField;
	Split = (QuestionResult = DialogReturnCode.Yes);
	StructureOfActions = AdditionalParameters.StructureOfActions; // Structure
	
	ThereIsPackage_ = CommonClientServer.HasAttributeOrObjectProperty(RowData, "Package");
	
	If TypeOf(RowData) = Type("Array") Then
		
		StringsList = New Array;
		For Each LineID In RowData Do
			CurrentRow = TabularSection.FindByID(LineID);
			StringsList.Add(CurrentRow);
		EndDo;
		
	Else
		StringsList = CommonClientServer.ValueInArray(RowData);
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	For Each CurrentRow In StringsList Do
		
		If ValueIsFilled(CurrentRow.OperationCategory) 
			And CurrentRow.StocktakingRecord Then
				
			QuantityPerLine = CurrentRow.Count - 1;
			
			CurrentRow[QuantityField] = 1;
			CurrentRow.Count = 1;
			
			If ThereIsPackage_ Then
				CurrentRow.Package = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
			EndIf;
			
			If StructureOfActions <> Undefined Then
				BatchProcessingOfTablePartClient.ProcessTSString(
					CurrentRow, StructureOfActions, CachedValues);
			EndIf;
			
			If Split Then
				
				While QuantityPerLine > 0 Do
					
					NewRow = TabularSection.Add();
					FillPropertyValues(NewRow, CurrentRow);
					NewRow.AssetID = "";
					
					If StructureOfActions <> Undefined Then
						BatchProcessingOfTablePartClient.ProcessTSString(
							CurrentRow, StructureOfActions, CachedValues);
					EndIf;
					
					QuantityPerLine = QuantityPerLine - 1;
					
				EndDo;
				
			EndIf;
			
		Else
			
			If Not CurrentRow.StocktakingRecord Then
				CurrentRow.AssetID = "";
			EndIf;
	
		EndIf;
		
	EndDo;

EndProcedure

Procedure FillInCategoryOfOperationCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	TabularSection = AdditionalParameters.TabularSection;
	SelectedRows = AdditionalParameters.SelectedRows;
	
	For Each RowID In SelectedRows Do
		
		RowData = TabularSection.FindByID(RowID);
		RowData.OperationCategory = Result;
		
	EndDo;
	
	If AdditionalParameters.DescriptionOfNotificationAfterFillingIn <> Undefined Then
		RunCallback(AdditionalParameters.DescriptionOfNotificationAfterFillingIn);
	EndIf;
	
EndProcedure

Procedure FillInIndividualCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	TabularSection = AdditionalParameters.TabularSection;
	SelectedRows = AdditionalParameters.SelectedRows;
	FieldName_Individual = AdditionalParameters.FieldName_Individual;
	
	For Each RowID In SelectedRows Do
		
		RowData = TabularSection.FindByID(RowID);
		RowData[FieldName_Individual] = Result;
		
	EndDo;
	
EndProcedure

#EndRegion
