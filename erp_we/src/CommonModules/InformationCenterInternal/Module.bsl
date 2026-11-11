#Region Public

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export	
	
	Types.Add(Metadata.InformationRegisters.ViewedInformationCenterData);
		
EndProcedure

// Fills the structure with arrays of supported versions of all subsystems to be versioned,
// using the names of subsystems as keys.
// Provides the functionality of the InterfaceVersion Web service.
// During implementation, it is necessary to change the body of the procedure so that it returns the current version sets (see example below).
//
// Parameters:
// SupportedVersionsStructure - Structure - description: the Keys are the names of the subsystems, and the Values are arrays of names of supported versions.
//
// Example:
//	Servertransmission of files
//	Version Array = New Array;
//	Array of versions.Add("1.0.1.1");	
//	Array of versions.Add("1.0.2.1"); 
//	Structure of supported versions.Insert("Servertransmission of files", array of versions);
//	End of servertransmission of files
//
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export

	VersionsArray = New Array;
	VersionsArray.Add("1.0.1.1");
	SupportedVersionsStructure.Insert("SupportServiceData", VersionsArray);
	
	VersionsArray = New Array;
	VersionsArray.Add("1.0.1.1");
	SupportedVersionsStructure.Insert("InformationReferences", VersionsArray);
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings
//	Settings - See ScheduledJobsOverridable.OnDefineScheduledJobSettings.Settings
//@skip-warning EmptyMethod - a feature of the implementation.
//
Procedure OnDefineScheduledJobSettings(Settings) Export
	
EndProcedure

// Generates a list of information security parameters.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
// ParametersTable - ValueTable:
//  * Name - String - parameter name.
//  * LongDesc - String - description of the parameter to display in the user interface.
//  * ForbiddenReading - Boolean - indicates that the IB parameter cannot be read. It can be set, for example, for
//                            passwords.
//  * RecordBan - Boolean - indicates that the IB parameter cannot be changed.
//  * Type - TypeDescription - type of parameter value. You can only use primitive types and
//                          enumerations that are present in the control application.
//
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
EndProcedure

// Called before attempting to write the values of is parameters
// to constants of the same name.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
// ParameterValues - Structure - the values of the parameters which you want to install.
// If the parameter value is set in this procedure
// , the corresponding key Value pair must be removed from the structure.
//
Procedure OnSetIBParametersValues(Val ParameterValues) Export
	
EndProcedure

// Gets a list of message handlers that are processed by the library's subsystems.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//  Handlers - ValueTable - for the composition of the fields, see the Exchange of messages.A new table of message processors.
// 
Procedure OnDefineMessagesChannelsHandlers(Handlers) Export
	
EndProcedure

// Fills the passed array with General modules that are handlers
//  for the received message interfaces.
//  @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  HandlersArray - Array - 
// 
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export
		
EndProcedure

// Register handlers for delivered data
//
// When you receive a notification about the availability of new shared data, the procedure is called
// Available data from modules registered through getprocesserssuppliable Data.
// A descriptor, the xdto Descriptor Object, is passed to the procedure.
// 
// If the available Data sets the Load argument to True, 
// the data is loaded, and the handle and path to the data file are passed to the procedure 
// Process the new data. The file will be automatically deleted after the procedure is completed.
// If the file was not specified in the service Manager, the argument value is Undefined.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters: 
//   Handlers-  ValueTable - table for adding handlers. Columns:
//   * DataKind - String - code of the data type processed by the handler
//   * HandlerCode - String - length 20 - will be used when restoring data processing after a failure
//   * Handler - CommonModule - a module containing the following export procedures:
//        Available New Data (Descriptor, Upload)  
//        Process New data(Descriptor, File path)
//        Processing Data is changed (Descriptor)
//
Procedure OnDefineSuppliedDataHandlers(Handlers) Export
	
	RegisterSuppliedDataHandlers(Handlers);
	
EndProcedure

// Adds to the list of Handlers of the procedure-the update handlers required by this subsystem.
//
// Parameters:
//   Handlers - See InfobaseUpdate.NewUpdateHandlerTable
// 
Procedure RegisterUpdateHandlers(Handlers) Export
	
	If SaaSOperations.DataSeparationEnabled() Then
		
		Handler = Handlers.Add();
		Handler.Version = "*";
		Handler.ExclusiveMode = False;
		Handler.SharedData = True;
		Handler.InitialFilling = True;
		Handler.Procedure = "InformationCenterInternal.CreateDictionaryOfCompletePathsToFormsInServiceModel";
		Handler.Comment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tạo từ điển đường dẫn đầy đủ đến các biểu mẫu trong danh mục ""%1"".';
				|ru = 'Сформировать словарь полных путей к формам в справочнике ""%1"".';
				|en = 'Generate a dictionary of full paths to forms in the ""%1"" catalog.'; fa = 'Generate a dictionary of full paths to forms in the ""%1"" catalog.';
				|it = 'Formare un dizionario dei percorsi completi delle forme nella Guida ""%1"".';
				|pl = 'Utwórz słownik pełnych ścieżek do formularzy w katalogu ""%1"".';
				|tr = '""%1"" katalogundaki formların tam yollarının sözlüğünü oluşturun.'"),
			Metadata.Catalogs.FullPathsToForms);
			
	Else
		
		Handler = Handlers.Add();
		Handler.Version = "*";
		Handler.Id = New UUID("f93cd97f-a84c-4a28-bda3-7c39d4fa55fd");
		Handler.InitialFilling = True;
		Handler.ExecutionMode = "Deferred";
		Handler.Procedure = "InformationCenterInternal.GenerateDictionaryOfCompletePathsToForms";
		Handler.Comment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tạo từ điển đường dẫn đầy đủ đến các biểu mẫu trong danh mục ""%1"".';
				|ru = 'Сформировать словарь полных путей к формам в справочнике ""%1"".';
				|en = 'Generate a dictionary of full paths to forms in the ""%1"" catalog.'; fa = 'Generate a dictionary of full paths to forms in the ""%1"" catalog.';
				|it = 'Formare un dizionario dei percorsi completi delle forme nella Guida ""%1"".';
				|pl = 'Utwórz słownik pełnych ścieżek do formularzy w katalogu ""%1"".';
				|tr = '""%1"" katalogundaki formların tam yollarının sözlüğünü oluşturun.'"),
			Metadata.Catalogs.FullPathsToForms);
		
	EndIf;
	
	Handler = Handlers.Add();
	Handler.Version = "1.0.5.12";
	Handler.ExclusiveMode = False;
	Handler.SharedData = True;
	Handler.InitialFilling = True;
	Handler.Procedure = "InformationCenterInternal.FillInHashOfFullPathToForm";
	
	Handler = Handlers.Add();
	Handler.Version = "1.0.3.35";
	Handler.ExclusiveMode = False;
	Handler.SharedData = True;
	Handler.InitialFilling = True;
	Handler.Procedure = "InformationCenterInternal.FillInEndDateOfRelevanceOfInformationLinks";
	
	Handler = Handlers.Add();
	Handler.Version = "1.0.7.2";
	Handler.ExclusiveMode = False;
	Handler.SharedData = True;
	Handler.InitialFilling = True;
	Handler.Procedure = "InformationCenterInternal.FillInInformationLinkFromConfiguration";
	
	If SaaSOperations.DataSeparationEnabled() Then
		
		Handler = Handlers.Add();
		Handler.Version = "*";
		Handler.ExclusiveMode = False;
		Handler.SharedData = True;
		Handler.Procedure = "InformationCenterInternal.UpdateInformationLinksForFormsInServiceModel";
		
	Else
		
		Handler = Handlers.Add();
		Handler.Version = "*";
		Handler.ExecutionMode = "Deferred";
		Handler.Id = New UUID("a6710034-fd9d-4f46-8ba5-e44ba86bf8fa");
		Handler.Procedure = "InformationCenterInternal.UpdateInformationLinksForFormsInLocalMode";
		Handler.Comment = NStr("vi = 'Cập nhật tham chiếu thông tin cho biểu mẫu.';
								|ru = 'Обновление информационных ссылок для форм.';
								|en = 'Update external links for forms.'; fa = 'Update external links for forms.';
								|it = 'Aggiorna i riferimenti informativi per i moduli.';
								|pl = 'Aktualizacja linków informacyjnych dla form.';
								|tr = 'Formlar için harici bağlantıları güncelleme'");
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region Internal

Procedure CreateDictionaryOfCompletePathsToFormsInServiceModel(Parameters = Undefined) Export

	GenerateDictionaryOfCompletePathsToForms(Parameters);
	
EndProcedure

// Fills in the directory "Polnyeputikformam" full paths to the forms.
//
Procedure GenerateDictionaryOfCompletePathsToForms(Parameters = Undefined) Export
	
	If SaaSOperations.SessionSeparatorUsage() Then
		Return;
	EndIf;
	
	ArrayOfForms = New Array; // Array of String
	ArrayOfForms.Add("DataProcessor.InformationCenter.Form.InformationCenter");
	
	InformationCenterServerOverridable.FormsWithInformationLinks(ArrayOfForms);
	
	// Forming a table with a list of full configuration forms
	TableOfForms = New ValueTable;
	TableOfForms.Columns.Add("FullFormPath", New TypeDescription("String"));
	TableOfForms.Columns.Add("Hash", New TypeDescription("String"));
	
	For Each FullFormPath In ArrayOfForms Do
		
		NewRow = TableOfForms.Add();
		NewRow.FullFormPath = FullFormPath;
		NewRow.Hash = InformationCenterServer.HashOfFullPathToForm(FullFormPath);
		
	EndDo;
	
	// Filling in the directory "Fullputicform"
	Query = New Query;
	Query.SetParameter("TableOfForms", TableOfForms);
	Query.Text =
	"SELECT
	|	TableOfForms.FullFormPath AS FullFormPath,
	|	SUBSTRING(TableOfForms.Hash, 1, 32) AS Hash
	|INTO TableOfForms
	|FROM
	|	&TableOfForms AS TableOfForms
	|
	|INDEX BY
	|	Hash
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FullPathsToForms.Ref AS Ref,
	|	FullPathsToForms.Hash AS Hash
	|INTO ExistingCompletePathsToForms
	|FROM
	|	Catalog.FullPathsToForms AS FullPathsToForms
	|
	|INDEX BY
	|	Hash
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfForms.FullFormPath AS FullFormPath
	|FROM
	|	TableOfForms AS TableOfForms
	|		LEFT JOIN ExistingCompletePathsToForms AS ExistingCompletePathsToForms
	|		ON TableOfForms.Hash = ExistingCompletePathsToForms.Hash
	|WHERE
	|	ExistingCompletePathsToForms.Ref IS NULL ";
	SelectingForms = Query.Execute().Select();
	While SelectingForms.Next() Do
		If ThereIsFormAlongFullPath(SelectingForms.FullFormPath) Then
			SetSafeModeDisabled(True);
			AddFullNameToCatalog(SelectingForms.FullFormPath);
			SetSafeModeDisabled(False);
		EndIf;
	EndDo;
	
EndProcedure

// When updating the configuration, you must update the list of Information links for forms.
// This happens through the service Manager.
//
Procedure UpdateInformationLinksForFormsInServiceModel() Export
	
	Try
		
		UpdateInformationLinksForFormsInLocalMode();
			
		If SaaSOperations.ServiceManagerEndpointConfigured() Then
			SetSafeModeDisabled(True);
			SetPrivilegedMode(True);
			ConfigurationName = Metadata.Name;
			ProxyWebService = InformationCenterServer.GetProxyInformationCenter_1_0_1_1();
			SetPrivilegedMode(False);
			SetSafeModeDisabled(False);
			Result = ProxyWebService.UpdateInfoReference(ConfigurationName);
			If Result Then 
				Return;
			EndIf;
			
			ErrorText = NStr("vi = 'Không thể cập nhật Tham chiếu thông tin';
							|ru = 'Не удалось обновить Информационные ссылки';
							|en = 'Cannot update external links'; fa = 'Cannot update external links';
							|it = 'Impossibile aggiornare i collegamenti informativi';
							|pl = 'Nie udało się aktualizować Odnośniki informacyjne';
							|tr = 'Harici bağlantılar güncellenemedi'");
			EventName = InformationCenterServer.GetEventNameForLog();
			WriteLogEvent(EventName, EventLogLevel.Error,,, ErrorText);
		EndIf;
		
	Except
		
		EventName = InformationCenterServer.GetEventNameForLog();
		WriteLogEvent(EventName, EventLogLevel.Error,,, 
			DetailErrorDescription(ErrorInfo()));
			
	EndTry;
	
EndProcedure

// When updating the configuration, you must update the list of Information links for forms.
// This happens through the service Manager.
//
Procedure UpdateInformationLinksForFormsInLocalMode(Parameters = Undefined) Export
	
	If SaaSOperations.SessionSeparatorUsage() Then
		Return;
	EndIf;
	
	ClearDuplicatesOfPredefinedElements();
	
	EventName = InformationCenterServer.GetEventNameForLog();
	
	CommonTemplates = InformationCenterServer.GetCommonTemplatesForInformationalLinks();
	For Each CommonTemplate In CommonTemplates Do
		
		PathToFile = GetTempFileName("xml");
		TextDocument = CommonTemplate;
		TextDocument.Write(PathToFile);
		
		Try
			SetSafeModeDisabled(True);
			DownloadInformationalLinks(PathToFile);
			SetSafeModeDisabled(False);
		Except
			ErrorInfo = ErrorInfo();
			WriteLogEvent(EventName, EventLogLevel.Error,,, 
				DetailErrorDescription(ErrorInfo));
		EndTry;
		
		Try
			DeleteFiles(PathToFile);
		Except
			ErrorInfo = ErrorInfo();
			WriteLogEvent(EventName, EventLogLevel.Error,,, 
				DetailErrorDescription(ErrorInfo));
		EndTry;
		
	EndDo;
	
EndProcedure

// Fills in the elements of the reference list "Informationsylkidlyform", for which 
// the end date of relevance is empty date "31.12.3999".
//
Procedure FillInEndDateOfRelevanceOfInformationLinks() Export 
	
	Query = New Query;
	Query.SetParameter("RelevantTo", '00010101000000');
	Query.Text =
	"SELECT
	|	InformationReferencesForForms.Ref AS InformationLink
	|FROM
	|	Catalog.InformationReferencesForForms AS InformationReferencesForForms
	|WHERE
	|	InformationReferencesForForms.RelevantTo = &RelevantTo
	|	AND NOT InformationReferencesForForms.DeletionMark";
	Selection = Query.Execute().Select();
	While Selection.Next() Do 
		
		InformationLink = Selection.InformationLink.GetObject(); // CatalogObject.InformationReferencesForForms
		InformationLink.Write();
		
	EndDo;
	
EndProcedure

// Fills in the hash (using the MD5 algorithm)of the full path to the form in the "fullpath Forms" reference.
//
Procedure FillInHashOfFullPathToForm() Export
	
	Query = New Query(
		"SELECT
		|	FullPathsToForms.Ref
		|FROM
		|	Catalog.FullPathsToForms AS FullPathsToForms
		|WHERE
		|	FullPathsToForms.Hash = &Hash");
	Query.SetParameter("Hash", "");
	Selection = Query.Execute().Select();
	While Selection.Next() Do 
		RecordObject_ = Selection.Ref.GetObject(); // CatalogObject.FullPathsToForms
		RecordObject_.Write();
	EndDo;
	
EndProcedure

// Fills in the "out of Configuration" attribute for informational links.
//
Procedure FillInInformationLinkFromConfiguration() Export
	
	EventName = InformationCenterServer.GetEventNameForLog();
	CommonTemplates = InformationCenterServer.GetCommonTemplatesForInformationalLinks();
	
	For Each CommonTemplate In CommonTemplates Do
		
		PathToFile = GetTempFileName("xml");
		TextDocument = CommonTemplate;
		TextDocument.Write(PathToFile);
		
		Namespace = DefineNamespaceByFile(PathToFile);
		If Namespace = Undefined Then 
			Continue;
		EndIf;
		
		ReadingInformationalLinks = New XMLReader; 
		ReadingInformationalLinks.OpenFile(PathToFile); 
		ReadingInformationalLinks.MoveToContent();
		ReadingInformationalLinks.Read();
		
		While ReadingInformationalLinks.NodeType = XMLNodeType.StartElement Do
			
			TypeOfInformationLink = XDTOFactory.Type(Namespace, "reference");
			InformationLink = XDTOFactory.ReadXML(ReadingInformationalLinks, TypeOfInformationLink);
			URL = InformationLink.address;
			If IsBlankString(URL) Then
				Continue;
			EndIf;
			
			Query = New Query(
				"SELECT
				|	InformationReferencesForForms.Ref AS InformationLink
				|FROM
				|	Catalog.InformationReferencesForForms AS InformationReferencesForForms
				|WHERE
				|	InformationReferencesForForms.Address LIKE &URL");
			Query.SetParameter("URL", URL);
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				ReferenceObject = Selection.InformationLink.GetObject();
				ReferenceObject.FromConfiguration = True;
				ReferenceObject.DataExchange.Load = True;
				ReferenceObject.Write();
			EndDo;
			
		EndDo;
		
		ReadingInformationalLinks.Close();
		
		Try
			DeleteFiles(PathToFile);
		Except
			ErrorInfo = ErrorInfo();
			WriteLogEvent(EventName, EventLogLevel.Error,,, 
				DetailErrorDescription(ErrorInfo));
		EndTry;
		
	EndDo;
	
EndProcedure

Procedure NewDataAvailable(Val Descriptor, ToImport, Val JSONDescriptor = False) Export
	
	If Descriptor.DataType = "InformationReferences" Then
		
		ConfigurationName = GetConfigurationNameByHandle(Descriptor);
		If ConfigurationName = Undefined Then 
			ToImport = False;
			Return;
		EndIf;
		
		ToImport = ?((Upper(Metadata.Name)) = Upper(ConfigurationName), True, False);
		
	EndIf;
	
EndProcedure

Procedure NewJSONDataAvailable(Val Descriptor, ToImport) Export
	
	NewDataAvailable(Descriptor, ToImport, True);
	
EndProcedure

Procedure ProcessNewData(Val Descriptor, Val PathToFile, Val JSONDescriptor = False) Export
	
	If Descriptor.DataType = "InformationReferences" Then
		SetSafeModeDisabled(True);
		ProcessInformationalLinks(Descriptor, PathToFile);
		SetSafeModeDisabled(False);
	EndIf;
	
EndProcedure

Procedure ProcessNewJSONData(Val Descriptor, Val PathToFile) Export
	
	ProcessNewData(Descriptor, PathToFile, True);
	
EndProcedure

// Called when data processing is canceled in the event of a failure
//
Procedure DataProcessingCanceled(Val Descriptor) Export 
	
	Return;
	
EndProcedure

// Detailed error text.
// 
// Parameters:
//  ErrorInfo - ErrorInfo - error information
// 
// Returns:
//  String - Detailed error text
Function DetailedErrorText(ErrorInfo) Export
	
	Return ErrorProcessing.DetailErrorDescription(ErrorInfo);

EndFunction

// The short text of the error.
// 
// Parameters:
//  ErrorInfo - ErrorInfo - error information
// 
// Returns:
//  String - Short error text
Function ShortErrorText(ErrorInfo) Export
	
	Return ErrorProcessing.BriefErrorDescription(ErrorInfo);

EndFunction

#EndRegion

#Region Private

Procedure ClearDuplicatesOfPredefinedElements()
	
	Query = New Query(
		"SELECT
		|	LinksForForms.Ref AS InformationLink
		|FROM
		|	Catalog.InformationReferencesForForms AS LinksForForms
		|		INNER JOIN Catalog.InformationReferencesForForms AS LinksForForms1
		|		ON LinksForForms.PredefinedDataName = LinksForForms1.PredefinedDataName
		|		AND LinksForForms.Ref < LinksForForms1.Ref
		|WHERE
		|	NOT LinksForForms.DeletionMark
		|	AND
		|	NOT LinksForForms1.DeletionMark
		|	AND LinksForForms.PredefinedDataName <> """"
		|	AND LinksForForms1.PredefinedDataName <> """"");
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		InformationLink = Selection.InformationLink.GetObject();
		InformationLink.PredefinedDataName = "";
		InformationLink.DeletionMark = True;
		InformationLink.DataExchange.Load = True;
		InformationLink.Write();
		
	EndDo;
	
EndProcedure

Function HierarchyOfTags()
	
	TagsTree = New ValueTree;
	TagsTree.Columns.Add("Name", New TypeDescription("String"));
	
	// Reading the general layout
	ContentOfTemplate = GetCommonTemplate("TagsMapToCommonForms").GetText();
	
	RecordsOfMatchingTagsAndForms = New XMLReader;
	RecordsOfMatchingTagsAndForms.SetString(ContentOfTemplate);
	
	CurTagInTree = Undefined;
	While RecordsOfMatchingTagsAndForms.Read() Do
		
		// Reading the current tag
		ThisIsTag = RecordsOfMatchingTagsAndForms.NodeType = 
			XMLNodeType.StartElement And Upper(TrimAll(RecordsOfMatchingTagsAndForms.Name)) = Upper("tag");
			
		If ThisIsTag Then 
			While RecordsOfMatchingTagsAndForms.ReadAttribute() Do 
				If Upper(RecordsOfMatchingTagsAndForms.Name) = Upper("name") Then
					CurTagInTree     = TagsTree.Rows.Add();
					CurTagInTree.Name = RecordsOfMatchingTagsAndForms.Value;
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		// Reading the form
		ThisIsForm = RecordsOfMatchingTagsAndForms.NodeType = 
			XMLNodeType.StartElement And Upper(TrimAll(RecordsOfMatchingTagsAndForms.Name)) = Upper("form");
			
		If Not ThisIsForm Then
			Continue;
		EndIf;	 
		
		While RecordsOfMatchingTagsAndForms.ReadAttribute() Do
			 
			If Upper(RecordsOfMatchingTagsAndForms.Name) = Upper("path") Then
				
				If CurTagInTree = Undefined Then 
					Break;
				EndIf;
				
				CurTreeElement     = CurTagInTree.Rows.Add();
				CurTreeElement.Name = RecordsOfMatchingTagsAndForms.Value;
				
				Break;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return TagsTree;
	
EndFunction

// Registers handlers of delivered data for the day and for the entire time
//
// Parameters:
//	Handlers - See MessagesExchangeOverridable.GetMessagesChannelsHandlers.Handlers
//
Procedure RegisterSuppliedDataHandlers(Val Handlers)
	
	Handler                = Handlers.Add();
	Handler.DataKind      = "InformationReferences";
	Handler.HandlerCode = "InformationReferences";
	Handler.Handler     = InformationCenterInternal;
	
EndProcedure

// Processes information links that came through the "Delivered data" mechanism.
//
// Parameters:
//  Descriptor - Structure - descriptor.
//  PathToFile - String - file path.
//
// @unavailable-in-safemode
Procedure ProcessInformationalLinks(Descriptor, PathToFile)
	
	DownloadInformationalLinks(PathToFile);
	
EndProcedure

// Name of the configuration by descriptor.
//
// Parameters:
//  Descriptor - Structure - descriptor.
//
// Returns:
//  String - configuration name.
//
Function GetConfigurationNameByHandle(Descriptor)
	
	For Each Characteristic In Descriptor.Properties.Property Do
		If Characteristic.Code = "PlacementObject" Then
			Try
				Return Characteristic.Value;
			Except
				EventName = InformationCenterServer.GetEventNameForLog();
				WriteLogEvent(EventName, EventLogLevel.Error,,,
					DetailErrorDescription(ErrorInfo()));
				Return Undefined;
			EndTry;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Loads of information and links to the directory.
//
// Parameters:
//  PathToFile - String - file path.
//  LocalMode_ - Boolean - True if local mode, false otherwise.
//
// @unavailable-in-safemode
Procedure DownloadInformationalLinks(PathToFile, LocalMode_ = True)
	
	// Tag tree formation
	TagsTree = HierarchyOfTags();
	
	UpdateDate = CurrentSessionDate();
	
	Namespace = DefineNamespaceByFile(PathToFile);
	If Namespace = Undefined Then
		Return;
	EndIf;
	TypeOfInformationLink = XDTOFactory.Type(Namespace, "reference"); 
	
	ReadingInformationalLinks = New XMLReader; 
	ReadingInformationalLinks.OpenFile(PathToFile); 
	ReadingInformationalLinks.MoveToContent();
	ReadingInformationalLinks.Read();
	
	While ReadingInformationalLinks.NodeType = XMLNodeType.StartElement Do
		
		InformationLink = XDTOFactory.ReadXML(ReadingInformationalLinks, TypeOfInformationLink);
		
		// Predefined element
		If Not IsBlankString(InformationLink.namePredifined) Then 
			Try
				WritePredefinedInformationLink(InformationLink, LocalMode_);
			Except
				EventName = InformationCenterServer.GetEventNameForLog();
				WriteLogEvent(EventName, EventLogLevel.Error,,,
					DetailErrorDescription(ErrorInfo()));
			EndTry;
			Continue;
		EndIf;
		
		// An ordinary element
		For Each Context In InformationLink.context Do 
			Try
				WriteLinkByContext(TagsTree, InformationLink, Context, UpdateDate, LocalMode_);
			Except
				EventName = InformationCenterServer.GetEventNameForLog();
				WriteLogEvent(EventName, EventLogLevel.Error,,,
					DetailErrorDescription(ErrorInfo()));
			EndTry;
		EndDo;
		
	EndDo;
	
	ReadingInformationalLinks.Close();
	
	ClearNonUpdatedLinks(UpdateDate, LocalMode_);
	
EndProcedure

Procedure WritePredefinedInformationLink(ReferenceObject, LocalMode_)
	
	Try
		RefValue = Catalogs.InformationReferencesForForms[ReferenceObject.namePredifined];
		CatalogItem = RefValue.GetObject(); // CatalogObject.InformationReferencesForForms
	Except
		EventName = InformationCenterServer.GetEventNameForLog();
		WriteLogEvent(EventName, EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	CatalogItem.Address                     = ReferenceObject.address;
	CatalogItem.RelevantFrom    = ReferenceObject.dateFrom;
	CatalogItem.RelevantTo = ReferenceObject.dateTo;
	CatalogItem.Description              = ReferenceObject.name;
	CatalogItem.ToolTip                 = ReferenceObject.helpText;
	CatalogItem.FromConfiguration            = LocalMode_;
	CatalogItem.Write();
	
EndProcedure

// @unavailable-in-safemode
Procedure ClearNonUpdatedLinks(UpdateDate, ClearLocal)
	
	SetPrivilegedMode(True);
	
	Query = New Query(
		"SELECT
		|	InformationReferencesForForms.Ref AS InformationLink
		|FROM
		|	Catalog.InformationReferencesForForms AS InformationReferencesForForms
		|WHERE
		|	InformationReferencesForForms.FromConfiguration = &Local_1
		|	AND InformationReferencesForForms.UpdateDate <> &UpdateDate
		|	AND NOT InformationReferencesForForms.Predefined");
	Query.SetParameter("Local_1", ClearLocal);
	Query.SetParameter("UpdateDate", UpdateDate);
	Selection = Query.Execute().Select();
	While Selection.Next() Do 
		
		Object = Selection.InformationLink.GetObject();
		Object.DataExchange.Load = True;
		Object.Delete();
		
	EndDo;
	
EndProcedure

Procedure WriteLinkByContext(TagsTree, ReferenceObject, Context, UpdateDate, LocalMode_)
	
	Result = CheckForFormNameByTag(Context.tag);
	If Result.ThisIsPathToForm Then 
		WriteLinkByContext_(ReferenceObject, Context, Result.FormPath, UpdateDate, LocalMode_);
		Return;
	EndIf;
	
	Tag             = Context.tag;
	FoundRow = TagsTree.Rows.Find(Tag, "Name");
	If FoundRow = Undefined Then 
		RecordLinkById(ReferenceObject, Context, UpdateDate, LocalMode_);
		Return;
	EndIf;
	
	For Each TreeRow In FoundRow.Rows Do 
		
		FormName = TreeRow.Name;
		LinkToFormPath = FormPathReferenceInCatalog(FormName);
		If LinkToFormPath.IsEmpty() Then 
			Continue;
		EndIf;
		
		WriteLinkByContext_(ReferenceObject, Context, LinkToFormPath, UpdateDate, LocalMode_);
		
	EndDo;
	
EndProcedure

Procedure RecordLinkById(ReferenceObject, Context, UpdateDate, LocalMode_)
	
	CatalogItem = Catalogs.InformationReferencesForForms.CreateItem();
	CatalogItem.Address                     = ReferenceObject.address;
	CatalogItem.Id             = Context.tag;
	CatalogItem.Weight                       = Context.weight;
	CatalogItem.RelevantFrom    = ReferenceObject.dateFrom;
	CatalogItem.RelevantTo = ReferenceObject.dateTo;
	CatalogItem.Description              = ReferenceObject.name;
	CatalogItem.ToolTip                 = ReferenceObject.helpText;
	CatalogItem.UpdateDate            = UpdateDate;
	CatalogItem.FromConfiguration            = LocalMode_;
	CatalogItem.Write();
	
EndProcedure

Procedure WriteLinkByContext_(ReferenceObject, Context, LinkToFormPath, UpdateDate, LocalMode_)
	
	Ref = ThereIsInformationLinkForThisForm(ReferenceObject.address, LinkToFormPath);
	
	If Ref = Undefined Then 
		CatalogItem = Catalogs.InformationReferencesForForms.CreateItem();
	Else
		CatalogItem = Ref.GetObject();
	EndIf;
	
	CatalogItem.Address                     = ReferenceObject.address;
	CatalogItem.Weight                       = Context.weight;
	CatalogItem.RelevantFrom    = ReferenceObject.dateFrom;
	CatalogItem.RelevantTo = ReferenceObject.dateTo;
	CatalogItem.Description              = ReferenceObject.name;
	CatalogItem.ToolTip                 = ReferenceObject.helpText;
	CatalogItem.FullFormPath          = LinkToFormPath;
	CatalogItem.UpdateDate            = UpdateDate;
	CatalogItem.Write();
	
EndProcedure

Function ThereIsInformationLinkForThisForm(Address, LinkToFormPath)
	
	Query = New Query;
	Query.SetParameter("FullFormPath", LinkToFormPath);
	Query.SetParameter("Address",            Address);
	Query.Text = "SELECT
	               |	InformationReferencesForForms.Ref AS Ref
	               |FROM
	               |	Catalog.InformationReferencesForForms AS InformationReferencesForForms
	               |WHERE
	               |	InformationReferencesForForms.FullFormPath = &FullFormPath
	               |	AND InformationReferencesForForms.Address LIKE &Address";
	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do 
		Return Selection.Ref;
	EndDo;
	
	Return Undefined;
	
EndFunction

Function CheckForFormNameByTag(Tag_)
	
	Result = New Structure("ThisIsPathToForm", False);
	
	Query = New Query;
	Query.SetParameter("FullFormPath", Tag_);
	Query.Text = 
	"SELECT
	|	FullPathsToForms.Ref AS Ref
	|FROM
	|	Catalog.FullPathsToForms AS FullPathsToForms
	|WHERE
	|	FullPathsToForms.FullFormPath LIKE &FullFormPath";
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then 
		Return Result;
	EndIf;
	
	Result.ThisIsPathToForm = True;
	QuerySelection = QueryResult.Select();
	While QuerySelection.Next() Do 
		Result.Insert("FormPath", QuerySelection.Ref);
		Return Result;
	EndDo;
	
	Raise StrTemplate(NStr("vi = 'Không thể xác định tên biểu mẫu theo nhãn - %1';
							|ru = 'Не удалось определить имя формы по тегу - %1';
							|en = 'Cannot determine the form name by tag %1'; fa = 'Cannot determine the form name by tag %1';
							|it = 'Non è stato possibile determinare il nome del modulo in base al tag - %1';
							|pl = 'Nie udało się określić nazwy formularza według tagu - %1';
							|tr = '%1 etiketi ile form ismi tespit edilemedi'"), Tag_);
	
EndFunction

// @unavailable-in-safemode
Procedure AddFullNameToCatalog(FullFormName)
	
	SetPrivilegedMode(True);
	CatalogItem = Catalogs.FullPathsToForms.CreateItem();
	CatalogItem.Description     = FullFormName;
	CatalogItem.FullFormPath = FullFormName;
	CatalogItem.Write();
	
EndProcedure

Function FormPathReferenceInCatalog(FullFormName)
	
	Query = New Query;
	Query.SetParameter("FullFormPath", FullFormName);
	Query.Text = 
	"SELECT
	|	FullPathsToForms.Ref AS Ref
	|FROM
	|	Catalog.FullPathsToForms AS FullPathsToForms
	|WHERE
	|	FullPathsToForms.FullFormPath LIKE &FullFormPath";
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	While Selection.Next() Do 
		Return Selection.Ref;
	EndDo;
	
	Return Catalogs.FullPathsToForms.EmptyRef();
	
EndFunction

Function DefineNamespaceByFile(PathToFile)
	
	ReadingInformationalLinks = New XMLReader; 
	ReadingInformationalLinks.OpenFile(PathToFile); 
	ReadingInformationalLinks.MoveToContent();
	ReadingInformationalLinks.Read();
	
	While ReadingInformationalLinks.NodeType = XMLNodeType.StartElement Do
		
		InformationLink = XDTOFactory.ReadXML(ReadingInformationalLinks);
		ReadingInformationalLinks.Close();
		
		If ValueIsFilled(InformationLink.Type().NamespaceURI) Then
			Return InformationLink.Type().NamespaceURI;
		Else
			EventName = InformationCenterServer.GetEventNameForLog() + 
			"." + NStr("vi = 'Tham chiếu thông tin';
						|ru = 'Информационные ссылки';
						|en = 'External links'; fa = 'پیوندهای خارجی';
						|it = 'Link informativi';
						|pl = 'Odnośniki informacyjne';
						|tr = 'Harici bağlantılar'", Common.DefaultLanguageCode());
			XMLWriter = New XMLWriter;
			XMLWriter.SetString();
			XDTOFactory.WriteXML(XMLWriter, InformationLink);
			ObjectPresentation = XMLWriter.Close();
			WriteLogEvent(EventName,EventLogLevel.Error,,,
				NStr("vi = 'Không thể xác định kiểu tham chiếu thông tin:';
					|ru = 'Не удалось определить тип информационной ссылки:';
					|en = 'Cannot determine an external link type:'; fa = 'Cannot determine an external link type:';
					|it = 'Impossibile determinare il tipo di collegamento informazioni:';
					|pl = 'Nie udało się określić typ odnośnika informacyjnego:';
					|tr = 'Harici bağlantı türü belirlenemedi:'")
				+ Chars.LF + Chars.LF + ObjectPresentation);
			
			Return Undefined;
			
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

// Returns: whether the configuration has a form with the given full path or not.
//
// Parameters:
//  FullFormPath - String - full path to the form.
//  WriteErrorToVZHR - Boolean - whether to log an error if this path is not present.
//
// Returns:
//  Boolean - True, if there is a form, False - otherwise.
//
Function ThereIsFormAlongFullPath(FullFormPath, WriteErrorToVZHR = True)
	
	If Metadata.FindByFullName(FullFormPath) <> Undefined Then
		Return True;
	EndIf;
	
	If WriteErrorToVZHR Then
		EventNameLR = InformationCenterServer.GetEventNameForLog()
			+ "."
			+ NStr("vi = 'Tham chiếu thông tin';
					|ru = 'Информационные ссылки';
					|en = 'External links'; fa = 'پیوندهای خارجی';
					|it = 'Link informativi';
					|pl = 'Odnośniki informacyjne';
					|tr = 'Harici bağlantılar'", Common.DefaultLanguageCode());
		
		WriteLogEvent(EventNameLR, EventLogLevel.Error,,,
			NStr("vi = 'Khi cập nhật danh sách biểu mẫu, trong cấu hình không tìm thấy biểu mẫu có đường dẫn đầy đủ:';
				|ru = 'При обновлении списка форм, в конфигурации не найдена в форма с полным путем:';
				|en = 'Form with the full path was not found in the configuration when updating the form list:'; fa = 'Form with the full path was not found in the configuration when updating the form list:';
				|it = 'Quando si aggiorna un elenco di moduli, la configurazione non viene trovata nel modulo con percorso completo:';
				|pl = 'Podczas aktualizacji listy form, w konfiguracji nie została wyszukana forma z pełną drogą:';
				|tr = 'Form listesini güncellerken, konfigürasyonda tam yola sahip form bulunamadı:'", 
				Common.DefaultLanguageCode()) + FullFormPath);
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion
