#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the status for the document object
//
// Parameters:
//	NewStatus - String - Name of the status that will be set for orders
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
//	Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.PlanStatuses[NewStatus];
	
	Status = MeaningOfNewStatus;
	
	Return CheckFilling();
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	Tasks.BudgetTask.CheckAvailabilityOfBudgetTaskForDocument(ThisObject, Cancel);
	CheckEffectOfBudgetingModel(WriteMode, Cancel);
	
	OptionParameters_ = New Structure("BudgetingModel", BudgetingModel);
	If Not GetFunctionalOption("UseBudgetConfirmation", OptionParameters_) Then
		Status = Enums.PlanStatuses.Upholded;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	AdditionalProperties.Insert("DeferredPosting",
		Common.ObjectAttributeValue(BudgetProfile, "UseDeferredPostingOfBudgetEntryForms"));
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	If AdditionalProperties.DeferredPosting Then
		BudgetingServer.PutDocumentInQueue(Ref);
		BudgetingServer.StartDeferredExecutionWithBackgroundTask(Ref);
	EndIf;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	ParametersStructure = New Structure("BudgetingModel", BudgetingModel);
	
	If Not GetFunctionalOption("GenerateBudgetsByCompanies", ParametersStructure) Then
		NotCheckedAttributeArray.Add("Organization");
	EndIf;
	
	If Not GetFunctionalOption("GenerateBudgetsByBusinessUnits", ParametersStructure) Then
		NotCheckedAttributeArray.Add("Department");
	EndIf;
	
	UseBudgetConfirmation = GetFunctionalOption("UseBudgetConfirmation", ParametersStructure);
	SavedDocumentStatus = Common.ObjectAttributeValue(Ref, "Status");

	If UseBudgetConfirmation And Not Users.RolesAvailable("ApprovalOfBudgets",, False) Then
			ThereIsAccessError = True;
			
			If Status = Enums.PlanStatuses.Upholded Then
				ErrorText = NStr("vi = 'Không có quyền truy cập để phê duyệt các trường hợp ngân sách.';
								|ru = 'Нет доступа на утверждение экземпляров бюджетов.';
								|en = 'No access to approve Budget entry forms.'; fa = 'No access to approve Budget entry forms.';
								|it = 'Accesso negato per l''approvazione dei documenti di budget.';
								|pl = 'Brak dostępu do zatwierdzenia egzemplarzy budżetów.';
								|tr = 'Bütçe giriş formunun onaylanmasına erişim mevcut değil.'");
			ElsIf SavedDocumentStatus = Enums.PlanStatuses.Upholded Then
				ErrorText = NStr("vi = 'Không có quyền truy cập để thay đổi các trường hợp ngân sách được phê duyệt.';
								|ru = 'Нет доступа на изменение утвержденных экземпляров бюджетов.';
								|en = 'No access to change the confirmed Budget entry forms.'; fa = 'No access to change the confirmed Budget entry forms.';
								|it = 'Accesso negato per la modifica dei documenti di budget approvati.';
								|pl = 'Brak dostępu do zmiany zatwierdzonych egzemplarzy budżetów.';
								|tr = 'Bütçe giriş formunun onaylanmasının değiştirilmesi işlemine erişim mevcut değil.'");
			Else
				ThereIsAccessError = False;
			EndIf;
			
			If ThereIsAccessError Then
				CommonClientServer.MessageToUser(
					ErrorText,
					ThisObject,
					, // Field
					, // DataPath
					Cancel);
			EndIf;
	EndIf;
		
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Status = Enums.PlanStatuses.UnderPreparation;
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument(FillingData = Undefined)
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("BeginOfPeriod") Then
			BeginOfPeriod = FillingData.BeginOfPeriod;
		EndIf;
		If FillingData.Property("PeriodEnding") Then
			PeriodEnding = FillingData.PeriodEnding;
		EndIf;
		If FillingData.Property("BudgetProfile") Then
			BudgetProfile = FillingData.BudgetProfile;
			BudgetingModel = Common.ObjectAttributeValue(BudgetProfile, "Owner");
		EndIf;
		If FillingData.Property("Organization") Then
			Organization = FillingData.Organization;
		EndIf;
		If FillingData.Property("Department") Then
			Department = FillingData.Department;
		EndIf;
		If FillingData.Property("Action") Then
			Action = FillingData.Action;
		EndIf;
	
		MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		If TypeOf(FillingData) = Type("Structure") Then
			Counter = 1;
			While Counter <= MaximumNumberOfAnalysts Do
				If FillingData.Property("Dimension" + Counter) Then
					ThisObject["Dimension" + Counter] = FillingData["Dimension" + Counter];
				EndIf;
				Counter = Counter + Counter;
			EndDo;
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.BudgetEntryForm") Then
		
		DetailsOfFoundation = Common.ObjectAttributesValues(FillingData, BudgetingClientServer.NamesOfBudgetAttributes());
		FillPropertyValues(ThisObject, DetailsOfFoundation, , "Date");
		
		Action = Enums.TypesOfBudgetEntryFormActions.AdjustByBudgetFlowItems;
		
	EndIf;
	
	If Not ValueIsFilled(BeginOfPeriod) Or Not ValueIsFilled(PeriodEnding) Then
		
		CurrentDate = CurrentSessionDate();
		If Not ValueIsFilled(BeginOfPeriod) Then
			BeginOfPeriod = CurrentDate;
		EndIf;
		
		If Not ValueIsFilled(PeriodEnding) Then
			PeriodEnding = CurrentDate;
		EndIf;
		
		If ValueIsFilled(BudgetProfile) Then
			Catalogs.BudgetProfiles.AlignDatesByBudgetFrequency(BudgetProfile, BeginOfPeriod, PeriodEnding);
		EndIf;
		
	EndIf;
	
	ActualDataLimit = Catalogs.BudgetProfiles.BorderOfActualDataByBudgetType(BudgetProfile, BeginOfPeriod);
	
	EmployeeResponsible = Users.CurrentUser();
	
	If Not ValueIsFilled(BudgetingModel) Then
		BudgetingModel = Catalogs.BudgetingModels.DefaultBudgetingModel();
	EndIf;
	
	If ValueIsFilled(BudgetingModel)
		And TypeOf(FillingData) <> Type("DocumentRef.BudgetEntryForm") Then
		Dimensions = Documents.BudgetEntryForm.DefaultBudgetMeasurements(BudgetingModel, EmployeeResponsible);
		For Each Dimension In Dimensions Do
			If Not ValueIsFilled(ThisObject[Dimension.Key]) Then
				ThisObject[Dimension.Key] = Dimension.Value;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure CheckEffectOfBudgetingModel(WriteMode, Cancel)
	If WriteMode = DocumentWriteMode.Posting Then
		Valid = Catalogs.BudgetingModels.BudgetingModelWorks(BudgetingModel);
		If Not Valid Then
			ErrorText = NStr("vi = 'Không thể kết chuyển, mô hình ngân sách không hợp lệ.';
							|ru = 'Проведение документа запрещено, модель бюджетирования не действует.';
							|en = 'Cannot post the document, budgeting model is invalid.'; fa = 'Cannot post the document, budgeting model is invalid.';
							|it = 'È vietata la registrazione del documento in contabilità, modello di budgeting non funziona.';
							|pl = 'Zaksięgowanie jest zabronione, model budżetowania nie działa.';
							|tr = 'Belge kaydetme yasak, bütçeleme modeli geçerli değil.'");
				CommonClientServer.MessageToUser(
					ErrorText,
					ThisObject,,,
					Cancel);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#EndIf
