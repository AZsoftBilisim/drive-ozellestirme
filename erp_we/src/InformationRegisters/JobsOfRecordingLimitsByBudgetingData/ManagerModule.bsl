#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds entries to the task register.
//
// Parameters:
//  Document - DocumentRef.CashVoucher, DocumentRef.BankAccountIssue - the document for which you want to add the assignment.
//
Procedure AddJob(Document) Export
	
	Job = New Structure;
	Job.Insert("JobsOfRecordingLimitsByBudgetingData", New Structure);
	Job.JobsOfRecordingLimitsByBudgetingData.Insert("Document", Document);
	
	DeferredJobs.Add(Job);
	
EndProcedure

// Starts the task of calculating the queue of production operations
//
Procedure RunJob() Export
	
	DeferredJobs.Run("JobsOfRecordingLimitsByBudgetingData");
	
EndProcedure

#EndRegion

#Region Internal

// Returns an indication of whether Registering Recorded movements in the Limit Data budgeting register is necessary for documents
// that affect the data of the output report on limits.
//
// Parameters:
//  DocumentsCount - Number - the calculated number of documents for which it is necessary to reflect the Registered Records by register
//
// Returns:
//  Boolean - True if there are documents to be reflected
//
Function ItIsRequiredToReflectLimitsAccordingToBudgetingData(DocumentsCount) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	COUNT(DISTINCT JobsOfRecordingLimitsByBudgetingData.Document) AS Count
	|FROM
	|	InformationRegister.JobsOfRecordingLimitsByBudgetingData AS JobsOfRecordingLimitsByBudgetingData";
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		DocumentsCount = 0;
	Else
		Selection = Result.Select();
		Selection.Next();
		DocumentsCount = Selection.Count;
	EndIf;
	
	Return (DocumentsCount > 0);
	
EndFunction
	
#EndRegion

#EndIf
