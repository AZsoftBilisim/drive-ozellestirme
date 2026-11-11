
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	// Lot
	If TypeOf(Parameters.ProductionLot) = Type("UUID") Then
		Object.ProductionLot = Catalogs.ProductionLots.GetRef(Parameters.ProductionLot);
	Else
		Object.ProductionLot = Parameters.ProductionLot;
	EndIf;
	
	// This instalment
	AttributesValues = Common.ObjectAttributesValues(Object.ProductionLot,
		"Document.Number, Code, BillOfMaterials");
	Object.BillOfMaterials = AttributesValues.BillOfMaterials;
	
	LotNumber = ObjectsPrefixesClientServer.DeleteLeadingZerosFromObjectNumber(
		AttributesValues.DocumentNumber);
	PartyPresentation = StrTemplate("%1.%2",
		TrimAll(LotNumber),
		Format(AttributesValues.Code, "NG=0"));
	Title = StrTemplate(NStr("vi = 'Điền lô hàng %1';
							|ru = 'Заполнение партии %1';
							|en = 'Fill the %1 lot'; fa = 'Fill the %1 lot';
							|it = 'Заполнение партии %1';
							|pl = 'Fill the %1 lot';
							|tr = '%1 lotunun doldurulması'"), PartyPresentation);
	
	// Stage
	If Parameters.Stage.IsEmpty() Then
		Query = New Query(
			"SELECT TOP 1
			|	Stages.Ref AS Stage
			|FROM
			|	Document.ProductionStage2_2 AS Stages
			|	
			|	LEFT JOIN InformationRegister.StandardScheduleOfProductionStages AS RegulatorySchedule
			|	ON Stages.Ref = RegulatorySchedule.ProductionStage
			|WHERE
			|	Stages.ProductionLot = &ProductionLot
			|	AND Stages.Posted
			|	AND Stages.Status <> VALUE(Enum.StatusesOfProductionStages2_2.Completed)
			|
			|ORDER BY
			|	ISNULL(RegulatorySchedule.DurationBeforeStart, -Stages.DurationBeforeProductionIssue)");
		Query.SetParameter("ProductionLot", Object.ProductionLot);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			Object.Stage = Selection.Stage;
		EndIf;
	Else
		Object.Stage = Parameters.Stage;
	EndIf;
	
	// Stage data
	If Not Object.Stage.IsEmpty() Then
		FillingValues = FillInValuesAccordingToStageData(Object.Stage);
		FillPropertyValues(ThisObject, FillingValues, "StagePresentation, BOMStage");
	EndIf;
	If BOMStage.IsEmpty() Then
		Items.BOMStage.Visible = True;
	EndIf;
	
	// Reading user settings
	SettingsValue = Common.CommonSettingsStorageLoad(
		"DataProcessor.ProductionLotDivision",
		"FillingInByBOM");
	If TypeOf(SettingsValue) = Type("Structure") Then
		FillPropertyValues(ThisObject, SettingsValue);
	EndIf;
	
	// Configuring elements
	Items.ReplaceMaterialsWithAnalogs.Enabled = ReserveMaterials;
	Items.AnalogsGroup.Visible = GetFunctionalOption("UseAlternativeMaterials");
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	CheckedAttributes.Clear();
	
	If Object.Stage.IsEmpty() Then
		MessageText = CommonClientServer.FillingErrorText(
			"Field", "FillType", NStr("vi = 'Chứng từ';
										|ru = 'Документ';
										|en = 'Document'; fa = 'سند';
										|it = 'Документ';
										|pl = 'Document';
										|tr = 'Belge'"));
		Common.MessageToUser(MessageText,,, "StagePresentation", Cancel);
	EndIf;
	
	If BOMStage.IsEmpty() Then
		MessageText = CommonClientServer.FillingErrorText(
			"Field", "FillType", NStr("vi = 'Công đoạn';
										|ru = 'Этап';
										|en = 'Stage'; fa = 'مرحله';
										|it = 'Этап';
										|pl = 'Etap';
										|tr = 'Aşama'"));
		Common.MessageToUser(MessageText,,, "BOMStage", Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StagePresentationOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not Object.Stage.IsEmpty() Then
		ShowValue(, Object.Stage);
	EndIf;
	
EndProcedure

&AtClient
Procedure StagePresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	AddressProductionProcessLotReference = ProductionProcessOfLotReferenceInStorage(
		Object.ProductionLot, UUID);
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("AddressInStorage", AddressProductionProcessLotReference);
	ParametersStructure.Insert("CurrentRef", Object.Stage);
	
	AdditionalAttributes = New Array;
	
	Attribute = New Structure;
	Attribute.Insert("Name", "DocumentNumber");
	Attribute.Insert("Title", NStr("vi = 'Số';
									|ru = 'Номер';
									|en = 'Number'; fa = 'شماره';
									|it = 'Номер';
									|pl = 'Numer';
									|tr = 'Numara'"));
	Attribute.Insert("Type", New TypeDescription("String",, New StringQualifiers));
	AdditionalAttributes.Add(Attribute);
	
	Attribute = New Structure;
	Attribute.Insert("Name", "Status");
	Attribute.Insert("Title", NStr("vi = 'Trạng thái';
									|ru = 'Статус';
									|en = 'Status'; fa = 'وضعیت';
									|it = 'Статус';
									|pl = 'Status';
									|tr = 'Durum'"));
	Attribute.Insert("Type", New TypeDescription("String",, New StringQualifiers));
	AdditionalAttributes.Add(Attribute);
	
	ParametersStructure.Insert("AdditionalAttributes", AdditionalAttributes);
	
	OpenForm(
		"Catalog.BillsOfMaterials.Form.ProductionProcessElementChoiceForm",
		ParametersStructure,
		ThisObject,,,,
		New CallbackDescription("StagePresentationSelection", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure StagePresentationSelection(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult <> Undefined Then
		Object.Stage = ClosingResult.Stage;
		
		FillingValues = FillInValuesAccordingToStageData(Object.Stage);
		FillPropertyValues(ThisObject, FillingValues, "StagePresentation, BOMStage");
		
		If BOMStage.IsEmpty() Then
			Items.BOMStage.Visible = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ReserveMaterialsOnChange(Item)
	
	ShouldSaveSettings = True;
	
	If Not ReserveMaterials Then
		ReplaceMaterialsWithAnalogs = False;
	EndIf;
	
	Items.ReplaceMaterialsWithAnalogs.Enabled = ReserveMaterials;
	
EndProcedure

&AtClient
Procedure ReplaceMaterialsWithAnalogsOnChange(Item)
	
	ShouldSaveSettings = True;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersExecutionResult

&AtClient
Procedure ExecutionResultSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.ExecutionResult.CurrentData;
	ShowValue(, CurrentData.Ref);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExecuteAction(Command)
	
	If OperationCompleted Then
		Close();
	Else
		ClearMessages();
		
		StartWaiting = PerformActionInBackground();
		
		If StartWaiting Then
			TimeConsumingOperationsClient.WaitCompletion(
				TimeConsumingOperation,
				New CallbackDescription("PerformActionInBackgroundCompletion", ThisObject),
				TimeConsumingOperationsClient.IdleParameters(ThisObject));
		ElsIf OperationCompleted Then
			Notify("ChangingSequenceOfStages", Object.ProductionLot);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformActionInBackgroundCompletion(Result, AddlParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		
		ProcessActionInBackground(Result);
		
		If OperationCompleted Then
			Notify("ChangingSequenceOfStages", Object.ProductionLot);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function FillInValuesAccordingToStageData(Stage)
	
	Query = New Query(
		"SELECT DISTINCT
		|	Document.Number             AS Number,
		|	Document.StageName AS StageName,
		|	CASE
		|		WHEN NOT ISNULL(Document.Stage.DeletionMark, FALSE)
		|			THEN Document.Stage
		|		ELSE ISNULL(ProductionStages.Ref, VALUE(Catalog.ProductionStages.EmptyRef))
		|	END                      AS BOMStage
		|FROM
		|	Document.ProductionStage2_2 AS Document
		|	
		|	LEFT JOIN Catalog.ProductionStages AS ProductionStages
		|	ON Document.BillOfMaterials = ProductionStages.Owner
		|		AND Document.Stage.Description = ProductionStages.Description
		|		AND NOT ProductionStages.DeletionMark
		|WHERE
		|	Document.Ref = &Ref");
	Query.SetParameter("Ref", Stage);
	Selection = Query.Execute().Select();
	
	Result = New Structure;
	Result.Insert("StagePresentation", "");
	Result.Insert("BOMStage", Catalogs.ProductionStages.EmptyRef());
	
	If Selection.Next() Then
		Result.StagePresentation = StrTemplate("%1 (%2)", Selection.StageName, Selection.Number);
		
		If Selection.Count() = 1 Then
			Result.BOMStage = Selection.BOMStage;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function ProductionProcessOfLotReferenceInStorage(ProductionLot, UUID)
	
	Tree = DataProcessors.ProductionLotDivision.TreeProductionProcess(ProductionLot, False);
	Return PutToTempStorage(Tree, UUID);
	
EndFunction

&AtServer
Function PerformActionInBackground()
	
	If Not CheckFilling() Then
		Return False;
	EndIf;
	
	ExecutionResult.Clear();
	
	// Saving Settings
	If ShouldSaveSettings Then
		ShouldSaveSettings = False;
		
		SettingsValue = New Structure;
		SettingsValue.Insert("ReserveMaterials", ReserveMaterials);
		SettingsValue.Insert("ReplaceMaterialsWithAnalogs", ReplaceMaterialsWithAnalogs);
	
		Common.CommonSettingsStorageSave(
			"DataProcessor.ProductionLotDivision",
			"FillingInByBOM",
			SettingsValue);
	EndIf;
	
	// Starting processing
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Action", DataProcessors.ProductionLotDivision.Actions().Fill);
	ProcedureParameters.Insert("ProductionLot", Object.ProductionLot);
	ProcedureParameters.Insert("Stage", Object.Stage);
	ProcedureParameters.Insert("BOMStage", BOMStage);
	ProcedureParameters.Insert("ReserveMaterials", ReserveMaterials);
	ProcedureParameters.Insert("ReplaceMaterialsWithAnalogs", ReplaceMaterialsWithAnalogs);
	ProcedureParameters.Insert("FormIdentifier", UUID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Điền lô sản xuất theo bảng kê chi tiết';
														|ru = 'Заполнение партии производства по спецификации';
														|en = 'Fill a production lot based on a bill of materials'; fa = 'Fill a production lot based on a bill of materials';
														|it = 'Заполнение партии производства по спецификации';
														|pl = 'Fill a production lot based on a bill of materials';
														|tr = 'Ürün reçetesine göre üretim lotunun doldurulması'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.ProductionLotDivision.PerformActionInBackground",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		StartWaiting = True;
	Else
		ProcessActionInBackground(TimeConsumingOperation);
		
		StartWaiting = False;
		TimeConsumingOperation = Undefined;
	EndIf;
	
	Return StartWaiting;
	
EndFunction

&AtServer
Procedure ProcessActionInBackground(Result)
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	ElsIf Result.Status = "Completed2" Then
		ResultStructure = GetFromTempStorage(Result.ResultAddress);
		If TypeOf(ResultStructure) = Type("Structure") Then
			For Each Message In ResultStructure.Messages Do
				Common.MessageToUser(Message);
			EndDo;
			
			If Not ResultStructure.Cancel Then
				OperationCompleted = True;
				
				AllStages = New Array;
				If ResultStructure.Property("ChangedStage") Then
					CommonClientServer.SupplementArray(AllStages, ResultStructure.ChangedStage);
				EndIf;
				If ResultStructure.Property("StageRemoved") Then
					CommonClientServer.SupplementArray(AllStages, ResultStructure.StageRemoved);
				EndIf;
				If ResultStructure.Property("StageCreated") Then
					CommonClientServer.SupplementArray(AllStages, ResultStructure.StageCreated);
				EndIf;
				Attributes = Common.ObjectsAttributesValues(AllStages, "Number,StageName");
				
				If ResultStructure.Property("ChangedStage") Then
					For Each Ref In ResultStructure.ChangedStage Do
						NewRow = ExecutionResult.Add();
						NewRow.Ref = Ref;
						NewRow.RefPresentation = Documents.ProductionStage2_2.PresentationStage(Attributes[Ref]);
						NewRow.Action = NStr("vi = 'Đã thay đổi';
											|ru = 'Изменен';
											|en = 'Changed'; fa = 'تغییریافته';
											|it = 'Изменен';
											|pl = 'Changed';
											|tr = 'Değiştirildi'");
					EndDo;
				EndIf;
				
				If ResultStructure.Property("StageRemoved") Then
					For Each Ref In ResultStructure.StageRemoved Do
						NewRow = ExecutionResult.Add();
						NewRow.Ref = Ref;
						NewRow.RefPresentation = Documents.ProductionStage2_2.PresentationStage(Attributes[Ref]);
						NewRow.Action = NStr("vi = 'Đã xóa';
											|ru = 'Удален';
											|en = 'Deleted'; fa = 'حذف‌شده';
											|it = 'Удален';
											|pl = 'Deleted';
											|tr = 'Silindi'");
					EndDo;
				EndIf;
				
				If ResultStructure.Property("StageCreated") Then
					For Each Ref In ResultStructure.StageCreated Do
						NewRow = ExecutionResult.Add();
						NewRow.Ref = Ref;
						NewRow.RefPresentation = Documents.ProductionStage2_2.PresentationStage(Attributes[Ref]);
						NewRow.Action = NStr("vi = 'Đã tạo';
											|ru = 'Создан';
											|en = 'Created'; fa = 'ایجادشده';
											|it = 'Создан';
											|pl = 'Created';
											|tr = 'Oluşturuldu'");
					EndDo;
				EndIf;
				
				If ResultStructure.Property("AdjustmentCreated") Then
					For Each Ref In ResultStructure.AdjustmentCreated Do
						NewRow = ExecutionResult.Add();
						NewRow.Ref = Ref;
						NewRow.RefPresentation = String(Ref);
						NewRow.Action = NStr("vi = 'Đã tạo';
											|ru = 'Создан';
											|en = 'Created'; fa = 'ایجادشده';
											|it = 'Создан';
											|pl = 'Created';
											|tr = 'Oluşturuldu'");
					EndDo;
				EndIf;
				
				Items.ExecuteAction.Title = NStr("vi = 'Đóng';
												|ru = 'Закрыть';
												|en = 'Close'; fa = 'بستن';
												|it = 'Закрыть';
												|pl = 'Close';
												|tr = 'Kapat'");
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion
