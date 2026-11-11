//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Description of the access restriction
// 
// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ObjectReadingAllowed(TermDocument)";
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Parameters:
//  TermsDocuments - Array of DocumentRef.ConditionsOfVendorRebates 
//  CompleteCalculations - Boolean - 
// 
// Returns:
//  Structure - Change the Status of the calculation:
// * HasErrors - Boolean 
// * ErrorInfo - String 
//
Function ChangeStatusOfCalculations(TermsDocuments, CompleteCalculations) Export
	
	SetPrivilegedMode(True);
	
	ChangeResult = New Structure;
	ChangeResult.Insert("HasErrors", False);
	ChangeResult.Insert("ErrorInfo", "");
	
	BeginTransaction();
	
	Try
		
		DataLock = New DataLock;
		DataLockItem = 
			DataLock.Add("InformationRegister.CompletedConditionsOfVendorRebates");
		DataLockItem.Mode = DataLockMode.Exclusive;
		DataLock.Lock();
		
		DocumentsOfConditionsToChange = TermsAndConditionsDocumentsWithDifferentStatusOfSettlements(TermsDocuments, CompleteCalculations);
		CurrentUser = Users.CurrentUser();
		
		For Each TermDocument In DocumentsOfConditionsToChange Do
			
			RecordSet = InformationRegisters.CompletedConditionsOfVendorRebates.CreateRecordSet();
			RecordSet.Filter.TermDocument.Set(TermDocument);
			
			NewRecord = RecordSet.Add();
			NewRecord.TermDocument = TermDocument;
			NewRecord.Completed = CompleteCalculations;
			NewRecord.EmployeeResponsible = CurrentUser;
			RecordSet.Write();
			
			DateInMilliseconds = CurrentUniversalDateInMilliseconds();
			RecordsetHistory = 
				InformationRegisters.CompletedConditionsOfVendorRebatesHistory.CreateRecordSet();
			RecordsetHistory.Filter.TermDocument.Set(TermDocument);
			RecordsetHistory.Filter.DateInMilliseconds.Set(DateInMilliseconds);
			
			NewHistoryEntry = RecordsetHistory.Add();
			NewHistoryEntry.TermDocument = TermDocument;
			NewHistoryEntry.RecordPeriod = CurrentSessionDate();
			NewHistoryEntry.DateInMilliseconds = DateInMilliseconds;
			NewHistoryEntry.Completed = CompleteCalculations;
			NewHistoryEntry.EmployeeResponsible = CurrentUser;
			RecordsetHistory.Write();
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorTemplate = NStr("vi = 'Không thể thay đổi trạng thái hạch toán do: %1.';
							|ru = 'Не удалось изменить статус расчетов по причине: %1.';
							|en = 'Cannot change the settlement status due to: %1.'; fa = 'Cannot change the settlement status due to: %1.';
							|it = 'Не удалось изменить статус расчетов по причине: %1.';
							|pl = 'Cannot change the settlement status due to: %1.';
							|tr = 'Alacak/borç muhasebesi durumu şu sebeple değiştirilemedi: %1.'");
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			ErrorPresentation);
		ChangeResult.HasErrors = True;
		ChangeResult.ErrorInfo = ErrorText;
		
	EndTry;
	
	Return ChangeResult;
	
EndFunction

#EndRegion

#Region Private

// Parameters:
//  TermsDocuments - Array of DocumentRef.ConditionsOfVendorRebates - Terms Documents
//  CompleteCalculations - Boolean - End value
// 
// Returns:
//  Array of DocumentRef.ConditionsOfVendorRebates
//
Function TermsAndConditionsDocumentsWithDifferentStatusOfSettlements(TermsDocuments, CompleteCalculations)
	
	Query = New Query;
	Query.SetParameter("TermsDocuments", TermsDocuments);
	Query.SetParameter("CompleteCalculations", CompleteCalculations);
	Query.Text = 
	"SELECT
	|	ConditionsOfVendorRebates.Ref AS TermDocument
	|FROM
	|	Document.ConditionsOfVendorRebates AS ConditionsOfVendorRebates
	|		LEFT JOIN InformationRegister.CompletedConditionsOfVendorRebates AS
	|			CompletedConditionsOfVendorRebates
	|		ON ConditionsOfVendorRebates.Ref = CompletedConditionsOfVendorRebates.TermDocument
	|WHERE
	|	ConditionsOfVendorRebates.Ref IN (&TermsDocuments)
	|	AND ISNULL(CompletedConditionsOfVendorRebates.Completed, FALSE) <> &CompleteCalculations";
	
	Return Query.Execute().Unload().UnloadColumn("TermDocument");
	
EndFunction

#EndRegion

#EndIf