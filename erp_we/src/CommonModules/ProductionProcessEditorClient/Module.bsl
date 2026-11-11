////////////////////////////////////////////////////////////////////////////////
// Procedures and functions of the Production Process Editor
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region ProductionStage

Procedure SetMaximumNumberOfProductBatchUnits(SplitRouteSheets, MaximumNumberOfProductUnitsLots) Export
	
	If Not SplitRouteSheets Then
		If MaximumNumberOfProductUnitsLots <> 0 Then
			MaximumNumberOfProductUnitsLots = 0;
		EndIf; 
	Else
		If MaximumNumberOfProductUnitsLots = 0 Then
			MaximumNumberOfProductUnitsLots = 1;
		EndIf;
	EndIf;
	
EndProcedure

#Region WorkCenterTypes

Procedure WorkCenterTypesBeforeAddRow(
													CurrentData,
													AllKindsOfWorkCenters,
													ElementAllKindsOfWorkCenters,
													OperatingProcedure,
													ThereIsSynchronousLoad,
													Cancel,
													ProductionIsUsed22 = True) Export
	
	If CurrentData = Undefined Then
		// You can use the standard addition
		Return;
	EndIf;
	
	Cancel = True;
	
	ParentElement = CurrentData.GetParent(); // FormDataTreeItem
	If ParentElement = Undefined Then
		CollectionOfMainTypesOfRC = AllKindsOfWorkCenters.GetItems();
	Else
		CollectionOfMainTypesOfRC = ParentElement.GetItems();
	EndIf; 
	
	NewRow = CollectionOfMainTypesOfRC.Add();
	NewRow.UnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Minute");
	NewRow.Use = True;
	
	ConfigureOrderOfWorkCenterTypes(AllKindsOfWorkCenters, OperatingProcedure, ProductionIsUsed22);
		
	FillInSimultaneousOperationParameters(
		NewRow, AllKindsOfWorkCenters, OperatingProcedure, ThereIsSynchronousLoad, ProductionIsUsed22);
	
	ElementAllKindsOfWorkCenters.CurrentRow = NewRow.GetID();
	ElementAllKindsOfWorkCenters.ChangeRow();
	
EndProcedure

Procedure AddAnAlternativeTypeOfRC(
										CurrentData,
										AllKindsOfWorkCenters,
										ElementAllKindsOfWorkCenters,
										OperatingProcedure,
										ThereIsSynchronousLoad,
										ProductionIsUsed22 = True) Export
	
	If CurrentData = Undefined Then
		// It is not clear for which type of RC you need to add an alternative
		Return;
	EndIf;
	
	ParentElement = CurrentData.GetParent(); // FormDataTreeItem
	If ParentElement = Undefined Then
		ParentElement = CurrentData;
	EndIf;
	
	CollectionOfAlternativeTypesOfRC = ParentElement.GetItems();
	
	NewRow = CollectionOfAlternativeTypesOfRC.Add();
	NewRow.UnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Minute");
	NewRow.AlternateType = True;
	
	FillInSimultaneousOperationParameters(
		NewRow, AllKindsOfWorkCenters, OperatingProcedure, ThereIsSynchronousLoad, ProductionIsUsed22);
	
	ElementAllKindsOfWorkCenters.CurrentRow = NewRow.GetID();
	ElementAllKindsOfWorkCenters.ChangeRow();
	
EndProcedure

Procedure WhenChangingCompositionOfTypesOfWorkCenters(AllKindsOfWorkCenters, OperatingProcedure, ProductionIsUsed22 = True) Export
	
	ConfigureOrderOfWorkCenterTypes(AllKindsOfWorkCenters, OperatingProcedure, ProductionIsUsed22);
	
EndProcedure

Procedure ConfigureOrderOfWorkCenterTypes(WorkCenterTypes, OperatingProcedure, ProductionIsUsed22)
	
	If WorkCenterTypes.GetItems().Count() > 1 Then
		
		If OperatingProcedure.IsEmpty() Then
			
			If ProductionIsUsed22 Then
				
				OperatingProcedure = PredefinedValue("Enum.OperatingProcedureOfWorkCenterTypes.Simultaneously");
				
			Else
				
				OperatingProcedure = PredefinedValue("Enum.OperatingProcedureOfWorkCenterTypes.Independently");
				
			EndIf;
			
		EndIf;
		
	Else
		
		If Not OperatingProcedure.IsEmpty() Then
			
			OperatingProcedure = Undefined;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure TypesOfWorkCentersRecalculateWorkingHours(
													CurrentData,
													WorkCenterTypes,
													OperatingProcedure,
													ThereIsSynchronousLoad,
													ProductionIsUsed22,
													ThereIsCalculationByFormulas) Export
	
	If (ProductionIsUsed22 = False
			Or OperatingProcedure <> PredefinedValue("Enum.OperatingProcedureOfWorkCenterTypes.Simultaneously")
			Or (ThereIsSynchronousLoad And Not CurrentData.SynchronousLoad)
		) Then
		Return;
	EndIf;
	SetRunningTimeWhenLoadingAtSameTime(WorkCenterTypes, CurrentData, ThereIsCalculationByFormulas);
	
EndProcedure

Procedure FillInSimultaneousOperationParameters(NewRow, WorkCenterTypes, OperatingProcedure, ThereIsSynchronousLoad, ProductionIsUsed22)
	
	If Not ProductionIsUsed22
		Or OperatingProcedure <> PredefinedValue("Enum.OperatingProcedureOfWorkCenterTypes.Simultaneously") Then
		
		Return
		
	EndIf;
	
	FillingValues = ValuesForFillingParametersOfSimultaneousOperation(WorkCenterTypes, ThereIsSynchronousLoad);
	
	If Not FillingValues = Undefined Then
		FillPropertyValues(NewRow, FillingValues, "OperationTime, UnitOfMeasure");
	EndIf;
	
EndProcedure

Function ValuesForFillingParametersOfSimultaneousOperation(WorkCenterTypes, ThereIsSynchronousLoad)
	
	Result = Undefined;
	
	For Each String In WorkCenterTypes.GetItems() Do
		
		For IndexOf = 0 To String.GetItems().Count() Do
			
			Item = ?(IndexOf = 0, String, String.GetItems()[IndexOf-1]);
			
			If ValueIsFilled(Item.OperationTime)
				And (Not ThereIsSynchronousLoad Or Item.SynchronousLoad) Then
			
				Result = Item;
				Break;
				
			EndIf;
			
		EndDo;
		
		If Result <> Undefined Then
			Break;
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Procedure OperatingProcedureOfWorkCenterTypesOnChange(WorkCenterTypes, OperatingProcedure, ThereIsSynchronousLoad, ThereIsCalculationByFormulas) Export
	
	If WorkCenterTypes.GetItems().Count() = 0
		Or OperatingProcedure <> PredefinedValue("Enum.OperatingProcedureOfWorkCenterTypes.Simultaneously") Then
		Return;
	EndIf;
	
	FillingValues = ValuesForFillingParametersOfSimultaneousOperation(WorkCenterTypes, ThereIsSynchronousLoad);
	
	If Not FillingValues = Undefined Then
		SetRunningTimeWhenLoadingAtSameTime(WorkCenterTypes, FillingValues, ThereIsCalculationByFormulas);
	EndIf;
	
EndProcedure

Procedure SetRunningTimeWhenLoadingAtSameTime(WorkCenterTypes, FillingValues, ThereIsCalculationByFormulas)
	
	For Each String In WorkCenterTypes.GetItems() Do
		
		For IndexOf = 0 To String.GetItems().Count() Do
			
			Item = ?(IndexOf = 0, String, String.GetItems()[IndexOf-1]);
			
			If Not Item.SynchronousLoad Then
				
				ListOfProperties = "OperationTime, UnitOfMeasure";
			
				If ThereIsCalculationByFormulas Then
					ListOfProperties = ListOfProperties + ", CalculationByFormula, QuantityCalculationAlgorithm";
				EndIf;
				
				FillPropertyValues(Item, FillingValues, ListOfProperties);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// When changing the "Use" attribute, the rows of work center types are changed
// 
// Parameters:
// 	RowData - FormDataStructure - contains string data
Procedure WorkCenterTypesUseOnChange(RowData) Export
	
	ItemParent = RowData.GetParent();
	If ItemParent = Undefined Then
		ItemParent = RowData;
		CollectionOfAlternatives = RowData.GetItems();
	Else
		CollectionOfAlternatives = ItemParent.GetItems();
	EndIf;
	
	For Each StringAlternative In CollectionOfAlternatives Do
		If StringAlternative.Use And StringAlternative <> RowData Then
			StringAlternative.Use = False;
		EndIf;
	EndDo;
	If ItemParent.Use And ItemParent <> RowData Then
		ItemParent.Use = False;
	EndIf;
	
EndProcedure

// Sets the usage flag in the table of work center types
// 
// Parameters:
// 	CollectionOfMainTypesOfRC - FormDataTreeItemCollection - collection of the main types of RC
Procedure TypesOfWorkCentersAndUses(CollectionOfMainTypesOfRC) Export
	
	// You need to check that the type of RC is selected
	For Each RowMainViewOfRC In CollectionOfMainTypesOfRC Do
		If RowMainViewOfRC.Use Then
			Continue;
		EndIf;
		CollectionOfAlternatives = RowMainViewOfRC.GetItems();
		AlternativeIsUsed = False;
		For Each StringAlternative In CollectionOfAlternatives Do
			If StringAlternative.Use Then
				AlternativeIsUsed = True;
				Break;
			EndIf;
		EndDo;
		If Not AlternativeIsUsed Then
			RowMainViewOfRC.Use = True;
		EndIf;
	EndDo;
	
EndProcedure

// Clears the selection settings by properties for the selected rows in the table of working center types
// 
// Parameters:
// 	WorkCenterTypes - FormDataCollection
// 	SelectionByProperties - FormDataCollection
Procedure TypesOfWorkCentersClearSelectionSettingsByProperties(WorkCenterTypes, SelectionByProperties) Export
	
	KeyArray = New Array;
	For Each RowID In WorkCenterTypes.SelectedRows Do
		
		RowData = WorkCenterTypes.RowData(RowID);
		
		If KeyArray.Find(RowData.ConnectionKey) = Undefined Then
			KeyArray.Add(RowData.ConnectionKey);
		EndIf;
		
		If Not RowData.AlternateType Then
			
			CollectionOfAlternatives = RowData.GetItems();
			For Each StringAlternative In CollectionOfAlternatives Do
				If KeyArray.Find(StringAlternative.ConnectionKey) = Undefined Then
					KeyArray.Add(StringAlternative.ConnectionKey);
				EndIf;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	Filter = New Structure("ConnectionKey");
	For Each ConnectionKey In KeyArray Do
		Filter.ConnectionKey = ConnectionKey;
		StringsList = SelectionByProperties.FindRows(Filter);
		For Each FoundRow In StringsList Do
			SelectionByProperties.Delete(FoundRow);
		EndDo; 
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region TechnologicalOperation

// Open the form for selecting Operations by classifier.
// 
// Parameters:
//  Form - ClientApplicationForm
//  CurrentObject - CatalogObject.ManufacturingOperations
//  CloseOnChoice - Boolean
Procedure OpenFormForSelectingOperationsByClassifier(Form, CurrentObject = Undefined, CloseOnChoice = True) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode",        True);
	FormParameters.Insert("CloseOnChoice", CloseOnChoice);
	If CurrentObject <> Undefined Then
		FormParameters.Insert("CurrentRef",       CurrentObject.ClassifierOfTechnologicalOperations);
		FormParameters.Insert("CurrentDescription", CurrentObject.Description);
	EndIf;
	
	OpenForm("Catalog.ManufacturingOperationClassifier.ChoiceForm",
		FormParameters,
		Form,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

Procedure OpenSetupOptionSelectionForm(WorkCenter, SetupSettings, FormOwner) Export
	
	Filter_Settings = New Structure;
	Filter_Settings.Insert("Owner", ProductionProcessEditorClientServer.WorkCenterType(WorkCenter));
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter_Settings);
	FormParameters.Insert("CurrentRow", SetupSettings);
	
	OpenForm("Catalog.SetupOptions.ChoiceForm",
		FormParameters,
		FormOwner);
	
EndProcedure

Procedure OperationOnClassifierAutoSelection(Text, ChoiceData, StandardProcessing, FieldForSearch) Export
	
	If StrLen(Text) < 2 Then
		Return;
	Else
		ChoiceData = ProductionProcessEditorServerCall.ClassifierOperationSelectionData(FieldForSearch, Text);
		If ChoiceData.Count() > 0 Then
			StandardProcessing = False;
		EndIf;
	EndIf;
	
EndProcedure

#Region AdditionalDetailsOfTypeOfOperation

// Sets the format for editing additional details of the operation type.
// 
// Parameters:
// 	Form - ClientApplicationForm
// 	ElementPrefix - String
Procedure AdditionalDetailsSetFormatForEditingStandards(Form, ElementPrefix = "") Export
	
	Items = Form.Items;
	
	MatchingElements = ProductionProcessEditorClientServer.MatchingElements(ElementPrefix);
	
	CurrentData = Items[MatchingElements.AddAttributes].CurrentData;
	
	Items[MatchingElements.AddAttributesValueMin].EditFormat = CurrentData.Format;
	Items[MatchingElements.AddAttributesValueMax].EditFormat = CurrentData.Format;
	
EndProcedure

Procedure AdditionalValueOfStandardWhenChanging(RowData, NormativeStandard) Export
	
	If RowData <> Undefined
		And RowData.ValueType.NumberQualifiers.AllowedSign = AllowedSign.Nonnegative
		And RowData[NormativeStandard] < 0 Then
		
		RowData[NormativeStandard] = -RowData[NormativeStandard];
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Editor

Procedure StartRecordingProcessData(Form, DataToEndEditing, Notification) Export
	
	If Form.LongTermOperationsStructure.DataWriter <> Undefined Then
		Return;
	EndIf;
	
	Form.LongTermOperationsStructure.DataWriter = ProductionProcessEditorServerCall.StartRecordingProcessData(
		DataToEndEditing, Form.UUID);
	
	If Form.LongTermOperationsStructure.DataWriter <> Undefined Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
		IdleParameters.OutputIdleWindow = True;
		IdleParameters.MessageText = ProductionProcessEditorClientServer.BackgroundDataRecordingOperation();
		
		TimeConsumingOperationsClient.WaitCompletion(
			Form.LongTermOperationsStructure.DataWriter,
			Notification,
			IdleParameters);
		
	EndIf;
	
EndProcedure

Function RecordingOfProcessDataEnd(Form, TimeConsumingOperation, AdditionalParameters) Export
	
	Form.LongTermOperationsStructure.DataWriter = Undefined;
	
	Result = ProductionProcessEditorClientServer.ResultOfRecordingTechnicalProcessConstructor();
	
	If TimeConsumingOperation <> Undefined Then
			
		JobResult = GetFromTempStorage(TimeConsumingOperation.ResultAddress);
		FillPropertyValues(Result, JobResult);
		
		If TimeConsumingOperation.Status = "Error" Or JobResult = Undefined Then
			MessageText = NStr("vi = 'Lỗi thực hiện xác định bản ghi. Chi tiết xem trong nhật ký sự kiện.';
								|ru = 'Ошибка выполнения задания записи. Подробности см. в журнале регистрации.';
								|en = 'An error occurred when executing the writing job. For details, see the Event log.'; fa = 'An error occurred when executing the writing job. For details, see the Event log.';
								|it = 'An error occurred when executing the writing job. For details, see the Event log.';
								|pl = 'An error occurred when executing the writing job. For details, see the Event log.';
								|tr = 'Kayıt görevi gerçekleştirilirken hata oluştu. Ayrıntılar için olay günlüğüne bakın.'");
			Picture = PictureLib.Error32;
		ElsIf JobResult.ThereAreStageRecordingErrors Then
			MessageText = StrTemplate(NStr("vi = 'Không thể cập nhật công đoạn theo nguyên nhân: %1';
											|ru = 'Не удалось обновить этап по причине: %1';
											|en = 'Cannot refresh the stage. Reason: %1'; fa = 'Cannot refresh the stage. Reason: %1';
											|it = 'Cannot refresh the stage. Reason: %1';
											|pl = 'Cannot refresh the stage. Reason: %1';
											|tr = 'Aşamanın güncellenememe nedeni: %1'"), JobResult.BriefErrorDescription);
			Picture = PictureLib.Error32;
		ElsIf JobResult.ThereAreErrorsInRecordingTechnicalProcess Then
			MessageText = StrTemplate(NStr("vi = 'Không thể ghi lại quy trình công nghệ của công đoạn do: %1';
											|ru = 'Не удалось записать технологический процесс этапа по причине: %1';
											|en = 'Cannot save the technological process of the stage. Reason: %1'; fa = 'Cannot save the technological process of the stage. Reason: %1';
											|it = 'Cannot save the technological process of the stage. Reason: %1';
											|pl = 'Cannot save the technological process of the stage. Reason: %1';
											|tr = 'Aşamanın teknolojik sürecinin kaydedilememe nedeni: %1'"), JobResult.BriefErrorDescription);
			Picture = PictureLib.Error32;
		Else
			MessageText = NStr("vi = 'Đã lưu quy trình công nghệ của công đoạn.';
								|ru = 'Технологический процесс этапа сохранен.';
								|en = 'Technological process of the stage is saved.'; fa = 'Technological process of the stage is saved.';
								|it = 'Technological process of the stage is saved.';
								|pl = 'Technological process of the stage is saved.';
								|tr = 'Aşamanın teknolojik süreci kaydedildi.'");
			Picture = PictureLib.Information32;
			AdditionalParameters.Property("CloseAtEnd", Result.CloseAtEnd);
		EndIf;
		
		ShowUserNotification(ProductionProcessEditorClientServer.BackgroundDataRecordingOperation(),,MessageText, Picture);
		
		Notify("ChangingProcessTechnology", AdditionalParameters.Stage);
		Notify("Write_QueueOfProductionOperations", New Structure("Department", AdditionalParameters.Department));
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure StartCreatingTypicalProcessTechnology(Form, DataForCreatingTechnicalProcess, Notification) Export
	
	If Form.LongTermOperationsStructure.CreatingTypicalProcessTechnology <> Undefined Then
		Return;
	EndIf;
	
	Form.LongTermOperationsStructure.CreatingTypicalProcessTechnology = ProductionProcessEditorServerCall.StartCreatingTypicalProcessTechnology(
		DataForCreatingTechnicalProcess, Form.UUID);
	
	If Form.LongTermOperationsStructure.CreatingTypicalProcessTechnology <> Undefined Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
		IdleParameters.OutputIdleWindow = True;
		IdleParameters.MessageText = ProductionProcessEditorClientServer.BackgroundOperationCreatingProcess();
		
		TimeConsumingOperationsClient.WaitCompletion(
			Form.LongTermOperationsStructure.CreatingTypicalProcessTechnology,
			Notification,
			IdleParameters);
		
	EndIf;
	
EndProcedure

Procedure CreatingTypicalProcessTechnologyCompletion(Form, TimeConsumingOperation) Export
	
	Form.LongTermOperationsStructure.CreatingTypicalProcessTechnology = Undefined;
	
	If TimeConsumingOperation <> Undefined Then
		
		JobResult = GetFromTempStorage(TimeConsumingOperation.ResultAddress);
		
		If TimeConsumingOperation.Status = "Error"
				Or JobResult = Undefined
				Or JobResult.HasErrors Then
			MessageText = NStr("vi = 'Không thể tạo quy trình công nghệ mới. Chi tiết xem trong nhật ký sự kiện.';
								|ru = 'Не удалось создать новый технологический процесс. Подробности см. в журнале регистрации.';
								|en = 'Cannot create a new technological process. For more information, see the Event log.'; fa = 'Cannot create a new technological process. For more information, see the Event log.';
								|it = 'Cannot create a new technological process. For more information, see the Event log.';
								|pl = 'Cannot create a new technological process. For more information, see the Event log.';
								|tr = 'Yeni teknolojik süreç oluşturulamadı. Ayrıntılar için olay günlüğüne bakın.'");
			Picture = PictureLib.Error32;
		Else
			MessageText = NStr("vi = 'Đã tạo quy trình công nghệ.';
								|ru = 'Технологический процесс создан.';
								|en = 'Technological process is created.'; fa = 'Technological process is created.';
								|it = 'Technological process is created.';
								|pl = 'Technological process is created.';
								|tr = 'Teknolojik süreç oluşturuldu.'");
			Picture = PictureLib.Information32;
			ShowValue(, JobResult.TechnologicalProcess);
		EndIf;
		
		ShowUserNotification(ProductionProcessEditorClientServer.BackgroundOperationCreatingProcess(),,MessageText, Picture);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

