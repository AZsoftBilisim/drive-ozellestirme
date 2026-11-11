#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Constructor of the structure that is used for filling in new documents.
// 
// Returns:
//  Structure - structure with keys:
//		* Date - Date -
//		* Department - CatalogRef.BusinessStructure -
//		* Shift - CatalogRef.Calendars -
//		* FillInPerformersFromPreviousShift - Boolean -
//
Function FillingData() Export
	
	Result = New Structure;
	
	Result.Insert("Date");
	Result.Insert("Department");
	Result.Insert("Shift");
	Result.Insert("ProductionArea");
	Result.Insert("FillInPerformersFromPreviousShift", False);
	
	Return Result;
	
EndFunction

// Creates and fills in new documents.
//
// Parameters:
//  ArrayOfFillInData - Array - array with filling data (See FillingData)
//                                    .
// 
// Returns:
//  Array of DocumentRef.ShiftTask - links to created documents.
//
Function CreateJobs(ArrayOfFillInData) Export
	
	References = New Array;
		
	BeginTransaction();
	
	Try
		
		For Each FillingData In ArrayOfFillInData Do
			
			Object = Documents.ShiftTask.CreateDocument();
			
			Object.Fill(FillingData);
			
			Object.Write(DocumentWriteMode.Posting);
			
			References.Add(Object.Ref);
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteLogEvent(
			NStr("vi = 'Ca làm việc';
				|ru = 'Сменные задания';
				|en = 'Shift tasks'; fa = 'وظایف شیفتی';
				|it = 'Task del turno';
				|pl = 'Zadania zmiany';
				|tr = 'Vardiyalı görevler'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,
			Metadata.Documents.ShiftTask,,
			DetailErrorDescription(ErrorInfo()));
		
		Raise NStr("vi = 'Không thể tạo việc làm theo ca';
					|ru = 'Не удалось создать сменные задания';
					|en = 'Cannot create shift tasks'; fa = 'Cannot create shift tasks';
					|it = 'Non è stato possibile creare task di turno';
					|pl = 'Nie udało się utworzyć zadań zmiennych';
					|tr = 'Vardiyalı görevler oluşturulmadı'");
		
	EndTry;
	
	Return References;
	
EndFunction

// Adds a new artist to the document.
//
// Parameters:
//  Ref		 - DocumentRef.ShiftTask - link to the document.
//  Assignees	 - Array - values with the reference Link type.Brigade, Spravochniki.Physical particle.
//
Procedure AddPerformers(Ref, Assignees) Export
	
	Try
		
		Object = Ref.GetObject();
		Object.Lock();
		
		For Each Performer In Assignees Do
			Object.Assignees.Add().Performer = Performer;
		EndDo;
		
		Object.Write(DocumentWriteMode.Write);
		
	Except
		
		WriteLogEvent(
			NStr("vi = 'Ca làm việc';
				|ru = 'Сменные задания';
				|en = 'Shift tasks'; fa = 'وظایف شیفتی';
				|it = 'Task del turno';
				|pl = 'Zadania zmiany';
				|tr = 'Vardiyalı görevler'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,
			Ref.Metadata(),
			Ref,
			DetailErrorDescription(ErrorInfo()));
		
		Raise StrTemplate(NStr("vi = 'Không thể thêm người thực hiện vào chứng từ %1';
								|ru = 'Не удалось добавить исполнителей в документ %1';
								|en = 'Cannot add assignees to the %1 document'; fa = 'Cannot add assignees to the %1 document';
								|it = 'Non è stato possibile aggiungere esecutori al documento %1';
								|pl = 'Nie udało się dodać wykonawców do dokumentu %1';
								|tr = '%1 belgesine atanan eklenemedi'"), Ref);
		
	EndTry;
	
EndProcedure

// Deletes the performer from the document.
//
// Parameters:
//  Ref		 - DocumentRef.ShiftTask - link to the document.
//  Performer	 - CatalogRef.Teams, CatalogRef.Persons - executor.
//
Procedure DeleteAssignee(Ref, Performer) Export
	
	Try
		
		Object = Ref.GetObject();
		Object.Lock();
		
		String = Object.Assignees.Find(Performer, "Performer");
		
		If String <> Undefined Then
			
			Object.Assignees.Delete(String);
			Object.Write(DocumentWriteMode.Write);
			
		EndIf;
		
	Except
		
		WriteLogEvent(
			NStr("vi = 'Ca làm việc';
				|ru = 'Сменные задания';
				|en = 'Shift tasks'; fa = 'وظایف شیفتی';
				|it = 'Task del turno';
				|pl = 'Zadania zmiany';
				|tr = 'Vardiyalı görevler'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,
			Ref.Metadata(),
			Ref,
			DetailErrorDescription(ErrorInfo()));
		
		Raise StrTemplate(NStr("vi = 'Không thể xóa người thực hiện khỏi chứng từ %1';
								|ru = 'Не удалось удалить исполнителя из документа %1';
								|en = 'Cannot delete an assignee from the %1 document'; fa = 'Cannot delete an assignee from the %1 document';
								|it = 'Non è stato possibile rimuovere esecutore dal documento %1';
								|pl = 'Nie udało się usunąć wykonawcy z dokumentu %1';
								|tr = '%1 belgesinden atanan silinemedi'"), Ref);
		
	EndTry;
	
EndProcedure

// Sets the status of the document
//
// Parameters:
//		Ref - DocumentRef.ShiftTask - link to the document
//		Status - EnumRef.ShiftTaskStatuses - Status
//
Procedure SetStatus(Ref, Status) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Document.ShiftTask.SetStatus");
	
	SetStatusInsideTimeMeasurement(Ref, Status);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, OperationsCount(Ref, Status));
	
EndProcedure

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Command = Documents.WorkOutput.AddCreateCommandBasedOnCreatingNewEmployees(GenerationCommands);
	If Command = Undefined Then
		Return;
	EndIf;
	
	If Parameters.FormName = "Document.ShiftTask.Form.DocumentForm" 
		Or Parameters.FormName = "DataProcessor.GenerateShiftTasks.Workplace" Then

			Command.ParameterType = New TypeDescription ("DocumentRef.ShiftTask, DocumentRef.ProductionOperation2_2");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region StandardSubsystems

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Department)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.BatchEditObjects

// Returns the details of an object that is not recommended to edit
// by processing a batch update of account details.
//
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("Status");
	NotAttributesToEdit.Add("Department");
	NotAttributesToEdit.Add("ProductionArea");
	NotAttributesToEdit.Add("Shift");
	
	Return NotAttributesToEdit;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#Region Private

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	// The job change
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ShiftTask";
	PrintCommand.Presentation = NStr("vi = 'Ca làm việc';
									|ru = 'Сменное задание';
									|en = 'Shift task'; fa = 'وظیفه شیفت';
									|it = 'Task del turno';
									|pl = 'Zadanie zmianowe';
									|tr = 'Vardiyalı görev'");
	PrintCommand.CheckPostingBeforePrint = False;
	PrintCommand.Order = 1;
	
	// Shift task by performers
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ShiftTaskForPerformers";
	PrintCommand.Presentation = NStr("vi = 'Ca làm việc (người thực hiện)';
									|ru = 'Сменное задание (по исполнителям)';
									|en = 'Shift task (by assignees)'; fa = 'Shift task (by assignees)';
									|it = 'Task del turno (in base a esecutori)';
									|pl = 'Zadanie zmianowe (wg wykonawców)';
									|tr = 'Vardiyalı görev (atanana göre)'");
	PrintCommand.CheckPostingBeforePrint = False;
	PrintCommand.Order = 2;
	
	// The job change for work centers
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ShiftAssignmentForWorkCenters";
	PrintCommand.Presentation = NStr("vi = 'Nhiệm vụ theo ca (theo nguồn lực sản xuất)';
									|ru = 'Сменное задание (по рабочим центрам)';
									|en = 'Shift task (by work centers)'; fa = 'Shift task (by work centers)';
									|it = 'Task del turno (in base a centri di lavoro)';
									|pl = 'Zadanie zmianowe (wg stanowisk pracy)';
									|tr = 'Vardiyalı görev (iş merkezine göre)'");
	PrintCommand.CheckPostingBeforePrint = False;
	PrintCommand.Order = 3;
	
EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ShiftTask") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ShiftTask",
			NStr("vi = 'Ca làm việc';
				|ru = 'Сменное задание';
				|en = 'Shift task'; fa = 'وظیفه شیفت';
				|it = 'Task del turno';
				|pl = 'Zadanie zmianowe';
				|tr = 'Vardiyalı görev'"),
			CreatePrintedFormChangeableTask(ObjectsArray, PrintObjects, PrintParameters));
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ShiftTaskForPerformers") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ShiftTaskForPerformers",
			NStr("vi = 'Ca làm việc (người thực hiện)';
				|ru = 'Сменное задание (по исполнителям)';
				|en = 'Shift task (by assignees)'; fa = 'Shift task (by assignees)';
				|it = 'Task del turno (in base a esecutori)';
				|pl = 'Zadanie zmianowe (wg wykonawców)';
				|tr = 'Vardiyalı görev (atanana göre)'"),
			CreatePrintedFormChangeableTask(ObjectsArray, PrintObjects, PrintParameters, "Performer"));
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ShiftAssignmentForWorkCenters") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ShiftAssignmentForWorkCenters",
			NStr("vi = 'Nhiệm vụ theo ca (theo nguồn lực sản xuất)';
				|ru = 'Сменное задание (по рабочим центрам)';
				|en = 'Shift task (by work centers)'; fa = 'Shift task (by work centers)';
				|it = 'Task del turno (in base a centri di lavoro)';
				|pl = 'Zadanie zmianowe (wg stanowisk pracy)';
				|tr = 'Vardiyalı görev (iş merkezine göre)'"),
			CreatePrintedFormChangeableTask(ObjectsArray, PrintObjects, PrintParameters, "WorkCenter"));
		
	EndIf;
	
	PrintFormGeneration.FillInSendingParameters(
		OutputParameters.SendOptions,
		ObjectsArray,
		PrintFormsCollection);	
	
EndProcedure

Function CreatePrintedFormChangeableTask(ObjectsArray, PrintObjects, PrintParameters, GroupingOption="")
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Landscape;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_ShiftTask"+GroupingOption;
	
	Template = PrintManagement.PrintFormTemplate("Document.ShiftTask.PF_MXL_ShiftTask");
	
	Table = ChangeableTaskPrintedFormData(ObjectsArray, GroupingOption);
	LineNumber = 0;
	ReverseGroupingOption = ?(IsBlankString(GroupingOption),
		"",
		?(GroupingOption = "Performer", "WorkCenter", "Performer"));
	
	For IndexOf = 0 To Table.Count()-1 Do
		
		String = Table[IndexOf];
		
		If IndexOf = 0
			Or String.Ref <> Table[IndexOf-1].Ref
			Or Not IsBlankString(GroupingOption) And String[GroupingOption] <> Table[IndexOf-1][GroupingOption] Then
			
			If IndexOf <> 0 Then
				SpreadsheetDocument.PutHorizontalPageBreak();
			EndIf;
			
			LineNumber = 0;
			
			BeingGenerated = String.Status = Enums.ShiftTaskStatuses.BeingGenerated;
			AreaNames = AreaNames(Not IsBlankString(GroupingOption), BeingGenerated);
			
			// Title
			Area = Template.GetArea("Title");
	    	Area.Parameters.Number = ObjectsPrefixesClientServer.NumberForPrinting(String.Number, False, True);
			Area.Parameters.Date	= Format(String.Date, "DLF=D");
			
			BarcodingOfPrintForms.OutputBarcodeToTabularDocument(
				SpreadsheetDocument, Template, Area, String.Ref);
			
			SpreadsheetDocument.Put(Area);
			
	    	// Header
			If IsBlankString(GroupingOption) Then
				Area = Template.GetArea("Header");
			Else
				Area = Template.GetArea("HeaderWithDimensions");
				Area.Parameters.Group = ?(GroupingOption = "Performer",
					NStr("vi = 'Người thực hiện:';
						|ru = 'Исполнитель:';
						|en = 'Assignee:'; fa = 'مجری:';
						|it = 'Esecutore:';
						|pl = 'Wykonawca:';
						|tr = 'Atanan:'", Common.DefaultLanguageCode()),
					NStr("vi = 'Nguồn lực sản xuất';
						|ru = 'Рабочий центр:';
						|en = 'Work center:'; fa = 'مرکز کار:';
						|it = 'Centro operativo:';
						|pl = 'Centrum pracy:';
						|tr = 'İş merkezi:'", Common.DefaultLanguageCode()));
				Area.Parameters.DimensionValue_1 = String[GroupingOption];
				Area.Parameters.DimensionValue_1Presentation = String[PresentationOfGroupingOption(GroupingOption)];
			EndIf;
			
			Area.Parameters.Fill(String);
	    	SpreadsheetDocument.Put(Area);
	
			// The header of the table
			Area = Template.GetArea(AreaNames.TableHeader);
			If Not IsBlankString(GroupingOption) Then
				Area.Parameters.Group = ?(GroupingOption = "Performer",
					NStr("vi = 'Nguồn lực sản xuất';
						|ru = 'Рабочий центр:';
						|en = 'Work center:'; fa = 'مرکز کار:';
						|it = 'Centro operativo:';
						|pl = 'Centrum pracy:';
						|tr = 'İş merkezi:'", Common.DefaultLanguageCode()),
					NStr("vi = 'Người thực hiện:';
						|ru = 'Исполнитель:';
						|en = 'Assignee:'; fa = 'مجری:';
						|it = 'Esecutore:';
						|pl = 'Wykonawca:';
						|tr = 'Atanan:'", Common.DefaultLanguageCode()));
			EndIf;
		
			SpreadsheetDocument.Put(Area);
			
		EndIf;
		
		// String
		If String.ThereIsOperation Then
			
			LineNumber = LineNumber + 1;
			Area = Template.GetArea(AreaNames.TableRow);
			
			Area.Parameters.Fill(String);
			Area.Parameters.LineNumber = LineNumber;
			If ValueIsFilled(GroupingOption) Then
				Area.Parameters.DimensionValue_1 = String[ReverseGroupingOption];
				Area.Parameters.DimensionValue_1Presentation = String[PresentationOfGroupingOption(ReverseGroupingOption)];
			EndIf;
			
			SpreadsheetDocument.Put(Area);
			
		EndIf;
		
		// Footer
		If IndexOf = Table.Count()-1
			Or String.Ref <> Table[IndexOf+1].Ref
			Or Not IsBlankString(GroupingOption) And String[GroupingOption] <> Table[IndexOf+1][GroupingOption] Then
			
			SpreadsheetDocument.Put(Template.GetArea("TableFooter"));
			
		EndIf;
		
	EndDo;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
		
	Return SpreadsheetDocument;
		
EndFunction

Function PresentationOfGroupingOption(GroupingOption)
	
	If GroupingOption = "Performer" Then
		Return "PerformerPresentation"
	ElsIf GroupingOption = "WorkCenter" Then
		Return "WorkCenterPresentation"
	Else
		Return "Presentation"
	EndIf;
	
EndFunction

Function AreaNames(Group, BeingGenerated)
	
	ReturnStructure = New Structure("TableRow, TableHeader");
	If Group And BeingGenerated Then
		ReturnStructure.TableRow = "GroupingTableRowIsFormed";
		ReturnStructure.TableHeader = "HeaderOfDimensionTableIsFormed";
	ElsIf Not Group And BeingGenerated Then
		ReturnStructure.TableRow = "TableRowIsFormed";
		ReturnStructure.TableHeader = "TableHeaderIsFormed";
	ElsIf Group And Not BeingGenerated Then
		ReturnStructure.TableRow = "TableRowGrouping";
		ReturnStructure.TableHeader = "HeaderOfGroupingTable";
	Else
		ReturnStructure.TableRow = "TableRow";
		ReturnStructure.TableHeader = "TableHeader";
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

// Returns data for forming a printed form.
//
// Parameters:
//  ObjectsArray - Array - Array of links to objects that need to be printed.
//  GroupingOption - String - The name of the data grouping prop.
//
// Returns:
//  ValueTable - Where:
//   * Ref - DocumentRef.ShiftTask -
//
Function ChangeableTaskPrintedFormData(ObjectsArray, GroupingOption)
	
	QueryText = 
		"SELECT
		|	Job.Ref                      AS Ref,
		|	Job.Number                       AS Number,
		|	Job.Date                        AS Date,
		|	Job.Status                      AS Status,
		|	Job.Department               AS Department,
		|	Job.Department.Presentation AS DepartmentPresentation,
		|	Job.Shift                       AS Shift,
		|	Job.Shift.Presentation         AS ShiftPresentation,
		|
		|	ISNULL(Operations.WorkCenter, VALUE(Catalog.WorkCenters.EmptyRef)) AS WorkCenter,
		|	ISNULL(Operations.WorkCenter.Presentation, """")                              AS WorkCenterPresentation,
		|
		|	CASE
		|		WHEN Operations.Performer IS NULL
		|			OR Operations.Performer IN (UNDEFINED, VALUE(Catalog.Teams.EmptyRef))
		|			THEN VALUE(Catalog.Persons.EmptyRef)
		|		ELSE Operations.Performer
		|	END                            AS Performer,
		|	CASE
		|		WHEN Operations.Performer IS NULL
		|			OR Operations.Performer IN (UNDEFINED, VALUE(Catalog.Teams.EmptyRef))
		|			THEN """"
		|		ELSE Operations.Performer.Presentation
		|	END                            AS PerformerPresentation,
		|
		|	NOT Operations.Ref IS NULL     AS ThereIsOperation,
		|
		|	Operations.Operation                AS Operation,
		|	Operations.Description            AS OperationPresentation,
		|	Operations.RunTime         AS Time,
		|	Operations.ExecutionTimeUnitOfMeasure    AS TimeUnitOfMeasurement,
		|	Operations.Ref                  AS ProductionOperationLink,
		|	Operations.Number                   AS ProductionOperationNumber,
		|
		|	Operations.Count - Operations.CountCanceled AS CountPlan,
		|	Operations.CountReal                           AS CountReal
		|FROM
		|	Document.ShiftTask AS Job
		|		LEFT JOIN Document.ProductionOperation2_2 AS Operations
		|		ON Job.Ref = Operations.ShiftTask
		|WHERE
		|	Job.Ref IN(&ObjectsArray)
		|	AND Job.Status <> &StatusIsGenerated
		|
		|UNION ALL
		|
		|SELECT
		|	Job.Ref,
		|	Job.Number,
		|	Job.Date,
		|	Job.Status,
		|	Job.Department,
		|	Job.Department.Presentation,
		|	Job.Shift,
		|	Job.Shift.Presentation,
		|
		|	ISNULL(Operations.WorkCenter, VALUE(Catalog.WorkCenters.EmptyRef)),
		|	ISNULL(Operations.WorkCenter.Presentation, """"),
		|
		|	CASE
		|		WHEN Operations.Performer IS NULL
		|			OR Operations.Performer IN (UNDEFINED, VALUE(Catalog.Teams.EmptyRef))
		|			THEN VALUE(Catalog.Persons.EmptyRef)
		|		ELSE Operations.Performer
		|	END,
		|	CASE
		|		WHEN Operations.Performer IS NULL
		|			OR Operations.Performer IN (UNDEFINED, VALUE(Catalog.Teams.EmptyRef))
		|			THEN """"
		|		ELSE Operations.Performer.Presentation
		|	END,
		|
		|	NOT Operations.Operation IS NULL,
		|
		|	Operations.Operation,
		|	ISNULL(Queue.ProductionOperation.Description, Operations.Operation.Presentation),
		|	&OperationsRunTime,
		|	Operations.TimeUnitsOfMeasure,
		|	Operations.Count,
		|	0,
		|	UNDEFINED,
		|	UNDEFINED
		|FROM
		|	Document.ShiftTask AS Job
		|		LEFT JOIN InformationRegister.OperationsToCreateShiftTasks AS Operations
		|		ON Job.Ref = Operations.ShiftTask
		|		LEFT JOIN InformationRegister.QueueOfProductionOperations AS Queue
		|		ON Operations.Stage = Queue.Stage
		|			AND Operations.Operation = Queue.Operation
		|			AND Operations.OperationID = Queue.OperationID
		|			AND Queue.MainEntry_
		|WHERE
		|	Job.Ref IN(&ObjectsArray)
		|	AND Job.Status = &StatusIsGenerated";
	
	If IsBlankString(GroupingOption) Then
		QueryText = QueryText + " ORDER BY Ref, Operation AUTOORDER";
	Else
		QueryText = QueryText + " ORDER BY Ref, " + GroupingOption + ", Operation AUTOORDER";
	EndIf;
	
	QueryText = StrReplace(
		QueryText,
		"&OperationsRunTime",
		InformationRegisters.OperationsToCreateShiftTasks.QueryTextOperationTime_("Operations"));
	
	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("StatusIsGenerated", Enums.ShiftTaskStatuses.BeingGenerated);	
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#Region Other

// Parameters:
// 	Parameters - Structure - 
// 	StorageAddress - UUID - 
Procedure SetStatusInBackground(Parameters, StorageAddress) Export
	
	Try
		
		SetStatus(Parameters.Ref, Parameters.Status);
		
	Except
		
		PutToTempStorage(
			New Structure("Messages", GetUserMessages()),
			StorageAddress);
		
		Raise BriefErrorDescription(ErrorInfo());
		
	EndTry;
	
EndProcedure

Procedure SetStatusInsideTimeMeasurement(Ref, Status)
	
	BeginTransaction();
	
	Try
		
		DataLock = New DataLock;
		
		LockItem = DataLock.Add("Document.ShiftTask");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("Ref", Ref);
		
		DataLock.Lock();
		
		// Setting the status
		Object = Ref.GetObject();
		Object.Lock();
		Object.Status = Status;
		Object.Write();
		
		// Changing the register and production operations
		If Status = Enums.ShiftTaskStatuses.BeingGenerated Then
			
			InformationRegisters.OperationsToCreateShiftTasks.DocumentsInRegister(
				Ref);
			
		ElsIf Status = Enums.ShiftTaskStatuses.Generated_ Then
			
			InformationRegisters.OperationsToCreateShiftTasks.RegisterInDocuments(
				Ref,
				Enums.ProductionOperationStatuses.CreatedOn_);
			
		ElsIf Status = Enums.ShiftTaskStatuses.Closed Then
			
			InformationRegisters.OperationsToCreateShiftTasks.RegisterInDocuments(
				Ref,
				Enums.ProductionOperationStatuses.Executed);
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteLogEvent(
			NStr("vi = 'Ca làm việc';
				|ru = 'Сменные задания';
				|en = 'Shift tasks'; fa = 'وظایف شیفتی';
				|it = 'Task del turno';
				|pl = 'Zadania zmiany';
				|tr = 'Vardiyalı görevler'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,
			Ref.Metadata(),
			Ref,
			DetailErrorDescription(ErrorInfo()));
		
		Raise StrTemplate(NStr("vi = 'Không thể đặt trạng thái %1 chứng từ %2';
								|ru = 'Не удалось установить статус %1 документу %2';
								|en = 'Cannot set status %1 to document %2'; fa = 'Cannot set status %1 to document %2';
								|it = 'Non è stato possibile impostare lo stato %1 al documento %2';
								|pl = 'Nie udało się ustawić status %1 dla dokumentu %2';
								|tr = '%2 belgesine %1 durumu ayarlanamadı'"), Status, Ref);
		
	EndTry;
	
EndProcedure

Function OperationsCount(Ref, Status)
	
	Query = New Query;
	
	If Status = Enums.ShiftTaskStatuses.BeingGenerated Then
		
		Query.Text =
			"SELECT
			|	SUM(1) AS OperationsCount
			|FROM
			|	InformationRegister.OperationsToCreateShiftTasks AS Operations
			|WHERE
			|	Operations.ShiftTask = &Ref
			|
			|HAVING
			|	SUM(1) IS NOT NULL";
		
	Else
		
		Query.Text =
			"SELECT
			|	SUM(1) AS OperationsCount
			|FROM
			|	Document.ProductionOperation2_2 AS Operations
			|WHERE
			|	Operations.ShiftTask = &Ref
			|
			|HAVING
			|	SUM(1) IS NOT NULL";
		
	EndIf;
	
	Query.SetParameter("Ref", Ref);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		Return Selection.OperationsCount;
		
	Else
		
		Return 0;
		
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
