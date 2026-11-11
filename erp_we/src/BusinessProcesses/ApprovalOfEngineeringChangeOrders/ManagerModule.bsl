#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	If AccessRight("Insert", Metadata.Documents.EngineeringChangeOrder) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.EngineeringChangeOrder.Commands.InterchangeableSubstitutes.FullName();
		CreateBasedOnCommand.Presentation = Metadata.Documents.EngineeringChangeOrder.Commands.InterchangeableSubstitutes.Synonym;
		CreateBasedOnCommand.WriteMode = "Write";
		CreateBasedOnCommand.FunctionalOptions = "UseAlternativeMaterials";
		
	EndIf;
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds a command to create a business process "Approval of permits for the replacement of materials."
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined -
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.BusinessProcesses.ApprovalOfEngineeringChangeOrders) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.BusinessProcesses.ApprovalOfEngineeringChangeOrders.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.BusinessProcesses.ApprovalOfEngineeringChangeOrders);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseApprovalOfEngineeringChangeOrders";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns a structure with the name and parameters of the form opening
//
// Parameters:
//  TaskRef - TaskRef.PerformerTask - link to the task to get the form for
//  RoutePointRef - BusinessProcessRoutePointRef.ApprovalOfRequestForReturnOfGoodsFromCustomer - link
//                                                   to the business process route point to get the form for.
//
// Returns:
//  Structure - with properties:
//  * FormParameters - Structure - with properties:
//    ** Key - TaskRef - Link to the issue
//  * FormName - String - The name of the form.
//
Function TaskExecutionForm(Val TaskRef, Val RoutePointRef) Export
	
	If RoutePointRef = BusinessProcesses.ApprovalOfEngineeringChangeOrders.RoutePoints.ReadTheResults Then
		FormName = "BusinessProcess.ApprovalOfEngineeringChangeOrders.Form.TaskFormRead";
	ElsIf RoutePointRef = BusinessProcesses.ApprovalOfEngineeringChangeOrders.RoutePoints.ToAgreeOnEngineeringChangeOrderPermitForReplacementOfMaterials Then
		FormName = "BusinessProcess.ApprovalOfEngineeringChangeOrders.Form.ReviewerTaskForm";
	EndIf;
	
	Result = New Structure;
	Result.Insert("FormParameters", New Structure("Key", TaskRef));
	Result.Insert("FormName", FormName);
	
	Return Result;
	
EndFunction

// Called when executing a task from the list form
//
// Parameters:
//	TaskRef                - TaskRef.PerformerTask - Task
//	BusinessProcessRef         - BusinessProcessRef.ApprovalOfEngineeringChangeOrders - 
//	BusinessProcessRoutePoint - BusinessProcessRoutePointRef.ApprovalOfEngineeringChangeOrders - 
//
Procedure DefaultCompletionHandler(Val TaskRef, BusinessProcessRef, Val BusinessProcessRoutePoint) Export
	
	// setting default values for batch execution of tasks
	If BusinessProcessRoutePoint = BusinessProcesses.ApprovalOfEngineeringChangeOrders.RoutePoints.ToAgreeOnEngineeringChangeOrderPermitForReplacementOfMaterials Then
		
		Try
			LockDataForEdit(BusinessProcessRef);
		Except
			
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			
			ErrorText = NStr("vi = 'Khi thực hiện nhiệm vụ không thể phong tỏa %Ref%. %ErrorDescription%';
							|ru = 'При выполнении задачи не удалось заблокировать %Ref%. %ErrorDescription%';
							|en = 'Cannot lock %Ref% when executing the task. %ErrorDescription%'; fa = 'Cannot lock %Ref% when executing the task. %ErrorDescription%';
							|it = 'Nell''eseguire il task non è stato possibile sbloccare %Ref%. %ErrorDescription%';
							|pl = 'Podczas wykonywania zadania nie udało się zablokować %Ref%. %ErrorDescription%';
							|tr = 'Görevin gerçekleştirilmesi sırasında %Ref% engellenemedi. %ErrorDescription%'");
			ErrorText = StrReplace(ErrorText, "%Ref%",         BusinessProcessRef);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", ErrorDescription);
				
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
		
		ObjectApproval.ApprovalResult = Enums.ApprovalResults.Approved;
		
		ObjectApproval.Write();
		SetPrivilegedMode(False);
		
		UnlockDataForEdit(BusinessProcessRef);

	EndIf;
	
EndProcedure

// Returns the result of approval by the reviewer for the route point
//
// Parameters:
//	BusinessProcess - BusinessProcessRef.ApprovalOfEngineeringChangeOrders - 
//	RoutePoint - BusinessProcessRoutePointRef.ApprovalOfEngineeringChangeOrders - 
//
// Returns:
//	EnumRef.ApprovalResults - The result of coordination at the point of the route.
//
Function ResultOfCoordinationByRoutePoint(Val BusinessProcess, Val RoutePoint) Export
	
	Query = New Query("
		|SELECT
		|	ApprovalOfEngineeringChangeOrdersApprovalResults.ApprovalResult AS ApprovalResult
		|
		|FROM
		|	BusinessProcess.ApprovalOfEngineeringChangeOrders.ApprovalResults AS ApprovalOfEngineeringChangeOrdersApprovalResults
		|WHERE
		|	ApprovalOfEngineeringChangeOrdersApprovalResults.Ref = &Ref
		|	AND ApprovalOfEngineeringChangeOrdersApprovalResults.RoutePoint = &RoutePoint
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
//    BusinessProcess - BusinessProcessRef.ApprovalOfEngineeringChangeOrders - 
//
// Returns:
//    Number - The number of the latest version of the document.
//
Function LastVersionNumberOfItem(Val BusinessProcess) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query("
		|SELECT TOP 1
		|	ObjectsVersions.VersionNumber AS VersionNumber
		|FROM
		|	InformationRegister.ObjectsVersions AS ObjectsVersions
		|WHERE
		|	ObjectsVersions.Object = CAST (&BusinessProcess AS BusinessProcess.ApprovalOfEngineeringChangeOrders).SubjectOf
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
//	BusinessProcess - BusinessProcessRef.ApprovalOfEngineeringChangeOrders - 
//
// Returns:
//	Boolean - True, if there are differences, otherwise false.
//
Function LatestVersionOfItemIsDifferentFromAgreedOnes(Val BusinessProcess) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query("
		|SELECT
		|	MAX(ApprovalResults.VersionNumber)     AS AgreedVersionNumber,
		|	ISNULL(MAX(ObjectsVersions.VersionNumber),0) AS LastVersionNumber
		|FROM
		|	BusinessProcess.ApprovalOfEngineeringChangeOrders.ApprovalResults AS ApprovalResults
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
//	Boolean - True if versioning is used, otherwise false.
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

// Called when redirecting a task
//
// Parameters:
//	TaskRef  - TaskRef.PerformerTask - the forwarded task.
//	NewTaskRef  - TaskRef.PerformerTask - task for a new performer.
//
Procedure OnForwardTask(TaskRef, NewTaskRef) Export
	
	Return;
	
EndProcedure

// Checks the possibility of approval for an authorized user.
//
//
// Returns:
//	Boolean - True if the agreement is available to the user, otherwise false.
//
Function UserCanAgreeOnReplacementPermissions() Export

	If Users.IsFullUser() Then
	
		Return True;	
	
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	TRUE AS Flag
		|FROM
		|	InformationRegister.TaskPerformers AS TaskPerformers
		|WHERE
		|	TaskPerformers.PerformerRole = &PerformerRole
		|	AND TaskPerformers.Performer = &Performer";
	
	Query.SetParameter("Performer", Users.AuthorizedUser());
	Query.SetParameter("PerformerRole", 
		Common.PredefinedItem("Catalog.PerformerRoles.ApprovingPermitsForReplacementOfMaterials"));
	
	QueryResult = Query.Execute();
	
	Return Not QueryResult.IsEmpty();

EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Description of the logic of access rights restrictions
//
// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE TRUE
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(Author)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#Region InfobaseUpdate

// Setting the values of the Attributes of predefined elements of the directory of role executors
// related to the approval of replacement permissions.
//
Procedure InitializeExecutorRoles() Export
	
	ObjectMetadata = Metadata.Catalogs.PerformerRoles;
	
	BeginTransaction();
		
	Try
	
		ItemRef = Catalogs.PerformerRoles.ApprovingPermitsForReplacementOfMaterials;
		
		Block = New DataLock;
		LockItem = Block.Add(Metadata.Catalogs.PerformerRoles.FullName());
		LockItem.SetValue("Ref", ItemRef);
		Block.Lock();
		
		RoleObject1 = ItemRef.GetObject();
		RoleObject1.UsedWithoutAddressingObjects = True;
		RoleObject1.Write();
	
		CommitTransaction();
			
	Except
		RollbackTransaction();
		MessageText = NStr("vi = 'Không thể xử lý mục: %Ref% vì lý do: %Cause%';
							|ru = 'Не удалось обработать элемент: %Ref% по причине: %Cause%';
							|en = 'Cannot process the item: %Ref%. Reason: %Cause%'; fa = 'Cannot process the item: %Ref%. Reason: %Cause%';
							|it = 'Non è stato possibile elaborare l''elemento: %Ref% a causa di: %Cause%';
							|pl = 'Przetwarzanie elementu: %Ref% nie powiodło się z powodu: %Cause%';
							|tr = 'Öğe işlenemedi: %Ref% çünkü: %Cause%'");
		MessageText = StrReplace(MessageText, "%Ref%", ItemRef);
		MessageText = StrReplace(MessageText, "%Cause%", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Warning,
			ObjectMetadata,
			ItemRef,
			MessageText);
	EndTry;
	
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
	
EndProcedure

#EndRegion

#EndRegion

#EndIf