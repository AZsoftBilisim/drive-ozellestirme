#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public


// Adds an object creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:
// 	Undefined - FormCommand
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseInternalApprovalOfRequestsForReturnOfGoodsFromCustomers";
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
EndFunction

// Returns a structure with the name and parameters of the form opening
//
// Parameters:
//	TaskRef - TaskRef.PerformerTask - link to the task to get the form for
//	RoutePointRef - BusinessProcessRoutePointRef - link
//							to the business process route point to get the form for.
//
// Returns:
//	Structure - fields parameterform, formname.
//
Function TaskExecutionForm(Val TaskRef, Val RoutePointRef) Export
	
	If RoutePointRef = BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer.RoutePoints.ReadTheResults Then
		FormName = "BusinessProcess.ApprovalOfRequestForReturnOfGoodsFromCustomer.Form.TaskFormRead";
	ElsIf RoutePointRef = BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer.RoutePoints.ApproveRequestForGoodsReturnFromTheCustomer
		Or RoutePointRef = BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer.RoutePoints.ApproveLogisticConditions
		Or RoutePointRef = BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer.RoutePoints.ApproveFinancialConditions
		Or RoutePointRef = BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer.RoutePoints.ApprovePriceConditions Then
		FormName = "BusinessProcess.ApprovalOfRequestForReturnOfGoodsFromCustomer.Form.ReviewerTaskForm";
	ElsIf RoutePointRef = BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer.RoutePoints.SummarizeApproval Then
		FormName = "BusinessProcess.ApprovalOfRequestForReturnOfGoodsFromCustomer.Form.TaskFormSummarize";
	EndIf;
		
	Result = New Structure;
	Result.Insert("FormParameters", New Structure("Key", TaskRef));
	Result.Insert("FormName", FormName);
	
	Return Result;
	
EndFunction

// Called when executing a task from the list form
//
// Parameters:
//  TaskRef                - TaskRef.PerformerTask - task.
//  BusinessProcessRef         - BusinessProcessRef.ApprovalOfRequestForReturnOfGoodsFromCustomer - instance of the approval process.
//  BusinessProcessRoutePoint - BusinessProcessRoutePointRef - route point for the approval process.
//
Procedure DefaultCompletionHandler(Val TaskRef, BusinessProcessRef, Val BusinessProcessRoutePoint) Export
	
	// setting default values for batch execution of tasks
	If BusinessProcessRoutePoint = BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer.RoutePoints.ApproveRequestForGoodsReturnFromTheCustomer Or
		BusinessProcessRoutePoint = BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer.RoutePoints.ApproveLogisticConditions Or
		BusinessProcessRoutePoint = BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer.RoutePoints.ApproveFinancialConditions Or
		BusinessProcessRoutePoint = BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer.RoutePoints.ApprovePriceConditions Or
		BusinessProcessRoutePoint = BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer.RoutePoints.SummarizeApproval Then
		
		Try
			LockDataForEdit(BusinessProcessRef);
		Except
				
			ErrorText = NStr("vi = 'Khi thực hiện nhiệm vụ không thể phong tỏa %Ref%. %ErrorDescription%';
							|ru = 'При выполнении задачи не удалось заблокировать %Ref%. %ErrorDescription%';
							|en = 'Cannot lock %Ref% when executing the task. %ErrorDescription%'; fa = 'Cannot lock %Ref% when executing the task. %ErrorDescription%';
							|it = 'Nell''eseguire il task non è stato possibile sbloccare %Ref%. %ErrorDescription%';
							|pl = 'Podczas wykonywania zadania nie udało się zablokować %Ref%. %ErrorDescription%';
							|tr = 'Görevin gerçekleştirilmesi sırasında %Ref% engellenemedi. %ErrorDescription%'");
			ErrorText = StrReplace(ErrorText, "%Ref%",         BusinessProcessRef);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
				
			Raise ErrorText;
			
		EndTry;
		
		SetPrivilegedMode(True);
	
		ObjectApproval = BusinessProcessRef.GetObject();
		
		ObjectApproval.AddApprovalResult(
			BusinessProcessRoutePoint,
			Users.CurrentUser(),
			Enums.ApprovalResults.Approved,
			,
			CurrentSessionDate());
		
		If BusinessProcessRoutePoint = BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer.RoutePoints.SummarizeApproval Then
			ObjectApproval.ApprovalResult = Enums.ApprovalResults.Approved;
		EndIf;
		
		ObjectApproval.Write();
		SetPrivilegedMode(False);
		
		UnlockDataForEdit(BusinessProcessRef);

	EndIf;
	
EndProcedure

// Returns the result of approval by the reviewer for the route point.
//
// Parameters:
//   BusinessProcess - BusinessProcessRef.ApprovalOfRequestForReturnOfGoodsFromCustomer - current business approval process.
//   RoutePoint - BusinessProcessRoutePointRef - the current route point of the business process.
//
// Returns:
//   EnumRef.ApprovalResults - The result of coordination at the point of the route.
//
Function ResultOfCoordinationByRoutePoint(Val BusinessProcess, Val RoutePoint) Export
	
	Query = New Query("
		|SELECT
		|	ApprovalOfRequestForReturnOfGoodsFromCustomerApprovalResults.ApprovalResult AS ApprovalResult
		|
		|FROM
		|	BusinessProcess.ApprovalOfRequestForReturnOfGoodsFromCustomer.ApprovalResults AS ApprovalOfRequestForReturnOfGoodsFromCustomerApprovalResults
		|WHERE
		|	ApprovalOfRequestForReturnOfGoodsFromCustomerApprovalResults.Ref = &Ref
		|	AND ApprovalOfRequestForReturnOfGoodsFromCustomerApprovalResults.RoutePoint = &RoutePoint
		|");
		
	Query.SetParameter("Ref",        BusinessProcess);
	Query.SetParameter("RoutePoint", RoutePoint);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return Selection.ApprovalResult;
	Else
		Return Undefined;
	EndIf;
		
EndFunction

// Returns the number of the latest version of the item
//
// Parameters:
//  BusinessProcess - BusinessProcessRef.ApprovalOfRequestForReturnOfGoodsFromCustomer - a business process
//                                                                                     that gets a version number for the subject.
//
// Returns:
//   Number - The number of the latest version of the document.
//
Function LastVersionNumberOfItem(Val BusinessProcess) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query("
		|SELECT TOP 1
		|	ObjectsVersions.VersionNumber AS VersionNumber
		|FROM
		|	InformationRegister.ObjectsVersions AS ObjectsVersions
		|WHERE
		|	ObjectsVersions.Object = CAST (&BusinessProcess AS BusinessProcess.ApprovalOfRequestForReturnOfGoodsFromCustomer).SubjectOf
		|
		|ORDER BY
		|	VersionNumber DESC
		|
		|");
		
	Query.SetParameter("BusinessProcess", BusinessProcess);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		VersionNumber = Selection.VersionNumber;
	Else
		VersionNumber = 0;
	EndIf;
	
	Return VersionNumber;

EndFunction

// Checks for differences between the latest version of the item and the approved ones
//
// Parameters:
//   BusinessProcess - BusinessProcessRef.ApprovalOfRequestForReturnOfGoodsFromCustomer - a business process
//                                                                                      whose subject versions are checked.
//
// Returns:
//   Boolean - True, if there are differences, otherwise false.
//
Function LatestVersionOfItemIsDifferentFromAgreedOnes(Val BusinessProcess) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query("
		|SELECT
		|	ISNULL(MAX(ApprovalResults.VersionNumber),0) AS AgreedVersionNumber,
		|	ISNULL(MAX(ObjectsVersions.VersionNumber),0)         AS LastVersionNumber
		|FROM
		|	BusinessProcess.ApprovalOfRequestForReturnOfGoodsFromCustomer.ApprovalResults AS ApprovalResults
		|LEFT JOIN
		|	InformationRegister.ObjectsVersions AS ObjectsVersions
		|ON
		|	ObjectsVersions.Object = ApprovalResults.Ref.SubjectOf
		|WHERE
		|	ApprovalResults.Ref = &BusinessProcess
		|");
		
	Query.SetParameter("BusinessProcess", BusinessProcess);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		If Selection.AgreedVersionNumber <> Selection.LastVersionNumber Then
			ThereAreDifferences = True;
		Else
			ThereAreDifferences = False;
		EndIf;
	Else
		ThereAreDifferences = False;
	EndIf;
	
	Return ThereAreDifferences;
	
EndFunction

// Checks the versioning usage of the subject of approval
//
// Parameters:
//	SubjectType - String - the full name of the object, such as " Document.Client's order".
//
// Returns:
//	Boolean -True if versioning is used, otherwise false.
//
Function VersioningOfItemIsUsed(Val SubjectType) Export
	
	SetPrivilegedMode(True);
	
	UseObjectsVersioning = GetFunctionalOption("UseObjectsVersioning");
	
	If Not UseObjectsVersioning Then
		Return False;
	EndIf;
		
	OptionParameters_ = New Structure();
	OptionParameters_.Insert("ObjectType", SubjectType);
		
	UseObjectVersioning = GetFunctionalOption("UseObjectVersioning", OptionParameters_);
	
	Return UseObjectVersioning;
	
EndFunction

// Called when a task is redirected.
//
// Parameters:
//  TaskRef  - TaskRef.PerformerTask - the forwarded task.
//  NewTaskRef  - TaskRef.PerformerTask - task for a new performer.
//
Procedure OnForwardTask(TaskRef, NewTaskRef) Export
	
	TaskObject = NewTaskRef.GetObject();
	LockDataForEdit(NewTaskRef);
	TaskObject.ExecutionResult = ExecutionResultOnForward(TaskRef) + 
		TaskObject.ExecutionResult;
	TaskObject.Write();
	
EndProcedure

#EndRegion

#Region Private

#Region InfobaseUpdate

// Setting the values of the details of predefined elements in the roles of Performers directory that
// relate to the approval of the item price setting.
//
Procedure InitializeExecutorRoles() Export
	
	RoleObject1 = Catalogs.PerformerRoles.ApproverOfRequestsForReturnOfGoodsFromCustomers.GetObject();
	RoleObject1.UsedWithoutAddressingObjects = True;
	RoleObject1.Write();
	
EndProcedure

#EndRegion

#Region Other

Function ExecutionResultOnForward(Val TaskRef)
	
	StringFormat = NStr("vi = '%1, %2 chuyển hướng nhiệm vụ:';
						|ru = '%1, %2 перенаправил(а) задачу:';
						|en = '%1, %2 forwarded the task:'; fa = '%1, %2 forwarded the task:';
						|it = '%1%2 ha reindirizzato il task:';
						|pl = '%1, %2 przekierował(a) zadanie:';
						|tr = '%1, %2 görevi yönlendirdi:'");
	StringFormat = StringFormat + Chars.LF + "%3" + Chars.LF;
	
	TaskAttributesRef = Common.ObjectAttributesValues(TaskRef, 
		"ExecutionResult, CompletionDate, Performer");
	
	Comment = TrimAll(TaskAttributesRef.ExecutionResult);
	Comment = ?(IsBlankString(Comment), "", Comment + Chars.LF);
	Result = StringFunctionsClientServer.SubstituteParametersToString(StringFormat,
		TaskAttributesRef.CompletionDate,
		TaskAttributesRef.Performer,
		Comment);
	
	Return Result;

EndFunction

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.ResultsOfApprovalOfRequestForReturnOfGoodsFromCustomer.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "BusinessProcessForm,ListForm";
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf


