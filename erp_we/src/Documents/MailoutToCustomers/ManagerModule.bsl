#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	
	
EndProcedure

// Adds the "Send to clients" document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - description of the added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.MailoutToCustomers) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.MailoutToCustomers.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.MailoutToCustomers);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseEmailClient";
	

		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Return; //In the future, the command code will be added
	
EndProcedure

// Returns an array of role names with the "Add" right for this document
//
// Returns:
//	Array - An array with the names of the roles.
//
Function NamesOfRolesWithRightToAdd() Export
	
	RolesArray = New Array;
	RolesArray.Add("FullAccess");
	Return RolesArray;
	
EndFunction

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region Private
// Generates a verification request when changing the status of the list of documents
//
// Parameters:
//	DocumentsArray - Array - An array of references to documents that should be reviewed
//	NewStatus - String - Name of the new status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.CustomerMailoutStatuses[NewStatus];
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
	|	PRESENTATION(&Status) AS PresentationOfNewStatus,
	|	CASE
	|		WHEN DocumentsTable.Status = &Status
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StatusMatches,
	|	TRUE AS Posted,
	|	DocumentsTable.DeletionMark AS DeletionMark,
	|	FALSE AS Recording,
	|	DocumentsTable.Status AS CurrentStatus
	|FROM
	|	Document.MailoutToCustomers AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string
//	NewStatus - EnumRef.CustomerMailoutStatuses - New status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Cancel = False;
	
	If ValidationSample.CurrentStatus = Enums.CustomerMailoutStatuses.InProcessing
		Or ValidationSample.CurrentStatus = Enums.CustomerMailoutStatuses.Executed Then
		
		ErrorText = NStr("vi = 'Trong chứng từ %Document% chưa thiết lập trạng thái ""%Status%"", bởi vì trạng thái hiện tại khác với ""Bản nháp"" và ""Cần gửi""';
						|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к. текущий статус отличается от ""Черновик"" И ""К отправке""';
						|en = 'The ""%Status%"" status of the %Document% document is not set as the current status differs from ""Draft"" and ""For dispatch""'; fa = 'The ""%Status%"" status of the %Document% document is not set as the current status differs from ""Draft"" and ""For dispatch""';
						|it = 'Per il documento %Document% non è impostato lo stato ""%Status%"" perché lo stato attuale è diverso da ""Bozza"" E ""Da inviare""';
						|pl = 'Dokument %Document% nie ma statusu ""%Status%"", ponieważ obecny status różni się od ""Brudnopis"" i ""Do wysłania""';
						|tr = 'Mevcut durum ""Taslak"" ve ""Gönderilecek"" durumlarından farklı olduğundan dolayı %Document% belgesinde ""%Status%"" durumu ayarlanmadı'");
		ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
		ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
		CommonClientServer.MessageToUser(ErrorText, ValidationSample.Ref);
		Cancel = True;
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction

#EndRegion

#EndIf
