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
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillPropertyValues(ThisObject, FillingData);
	EndIf;
	
	EmployeeResponsible = Users.CurrentUser();
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	Tasks.BudgetTask.CheckAvailabilityOfBudgetTaskForDocument(ThisObject, Cancel);
	
	If Not ValueIsFilled(Catalogs.BudgetingModels.BudgetingModel_UseBudgetConfirmation()) Then
		Status = Enums.PlanStatuses.Upholded;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If ValueIsFilled(CalculationRule) Then
		RuleDetails = Common.ObjectAttributesValues(CalculationRule, "DeletionMark, Status");
		If RuleDetails.DeletionMark Then
			ErrorText = NStr("vi = 'Việc kết chuyển chứng từ bị cấm, quy tắc tính toán bị đặt dấu xóa.';
							|ru = 'Проведение документа запрещено, правило расчета помечено на удаление.';
							|en = 'Cannot post the document. The calculation rule is marked for deletion.'; fa = 'Cannot post the document. The calculation rule is marked for deletion.';
							|it = 'Cannot post the document. The calculation rule is marked for deletion.';
							|pl = 'Cannot post the document. The calculation rule is marked for deletion.';
							|tr = 'Belgenin kaydedilmesi yasaktır, hesaplama kuralı silinmek üzere işaretlenmiş.'");
			Common.MessageToUser(ErrorText, ThisObject, , , Cancel);
		ElsIf RuleDetails.Status <> Enums.BudgetingRuleStatuses.Valid Then
			ErrorText = NStr("vi = 'Việc kết chuyển chứng từ bị cấm, quy tắc tính toán không còn hiệu lực.';
							|ru = 'Проведение документа запрещено, правило расчета не действует.';
							|en = 'Cannot post the document, the calculation rule is invalid.'; fa = 'Cannot post the document, the calculation rule is invalid.';
							|it = 'Cannot post the document, the calculation rule is invalid.';
							|pl = 'Cannot post the document, the calculation rule is invalid.';
							|tr = 'Belgenin kaydedilmesi yasaktır, hesaplama kuralı geçerli değil.'");
			Common.MessageToUser(ErrorText, ThisObject, , , Cancel);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf