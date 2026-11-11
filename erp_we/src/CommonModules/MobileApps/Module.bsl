#Region Public

#Region MethodsOfWorkingWithMobileApplicationsAndTheirVersions

// Gets a structure containing data about the mobile app version.
//
// Parameters:
//  ApplicationName - String - string with the name of the mobile app
//  VersionNumber - String - a string containing the version number of the mobile app.
//
// Returns:
//  Structure - structure containing data about the version of the mobile application
//
Function ApplicationDescription(ApplicationName, VersionNumber) Export
	
	QueryText = 
	"SELECT ALLOWED TOP 1
	|	MobileApplicationsVersions.Ref AS Ref,
	|	MobileApplicationsVersions.IsFolder AS IsFolder
	|FROM
	|	Catalog.MobileApplicationsVersions AS MobileApplicationsVersions
	|WHERE
	|	(NOT MobileApplicationsVersions.IsFolder)
	|	AND MobileApplicationsVersions.Code = &VersionNumber
	|	AND MobileApplicationsVersions.Parent.Description = &ApplicationName
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	MobileApplicationsVersions.Ref,
	|	MobileApplicationsVersions.IsFolder
	|FROM
	|	Catalog.MobileApplicationsVersions AS MobileApplicationsVersions
	|WHERE
	|	MobileApplicationsVersions.IsFolder
	|	AND MobileApplicationsVersions.Description = &ApplicationName"
	;
	
	Query = New Query();
	Query.Text = QueryText;
	Query.SetParameter("VersionNumber", VersionNumber);
	Query.SetParameter("ApplicationName", ApplicationName);
	
	ApplicationStructure = New Structure("Application,Version",Undefined,Undefined);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If Selection.IsFolder Then
			ApplicationStructure.Insert("Application", Selection.Ref);
		Else
			ApplicationStructure.Insert("Version", Selection.Ref);
		EndIf;	
	EndDo;
	
	Return ApplicationStructure;
	
EndFunction

// Writes the mobile app version to the directory based on the transmitted data.
//
// Parameters:
//  ApplicationName - String - string with the name of the mobile app.
//  VersionNumber - String - a string containing the version number of the mobile app.
//  Application - String - a mobile application in the form of an encoded string.
//  UsedMetadata - String - a string containing information about the metadata used by the application in XML format.
//  ApplicationStructure - Structure - a structure that contains information about the app.
//
Procedure WriteApp(ApplicationName, VersionNumber, Application, UsedMetadata, ApplicationStructure) Export
	
	If ApplicationStructure.Application = Undefined Then
		ObjectApplication = Catalogs.MobileApplicationsVersions.CreateFolder();
		ObjectApplication.Description = ApplicationName;
		ObjectApplication.Write();
		AppLink = ObjectApplication.Ref;
	Else
		AppLink = ApplicationStructure.Application;

		If AppLink.DeletionMark Then
			ObjectApplication = AppLink.GetObject();
			ObjectApplication.DeletionMark = False;
			ObjectApplication.Write();
		EndIf;
	EndIf;
	
	If ApplicationStructure.Version = Undefined Then
		VersionObject = Catalogs.MobileApplicationsVersions.CreateItem();
		VersionObject.Parent = AppLink;
		VersionObject.Code = VersionNumber;
		VersionObject.Description = ApplicationName + "," + NStr("vi = 'phiên bản';
																|ru = 'версия';
																|en = 'version'; fa = 'version';
																|it = 'versione';
																|pl = 'version';
																|tr = 'Sürüm'") + ": " + VersionNumber;
	Else
		VersionObject = ApplicationStructure.Version.GetObject();
	EndIf;
	
	VersionObject.MobileApplication = Application;
	VersionObject.UsedMetadata = UsedMetadata;
	VersionObject.DeletionMark = False;
	
	VersionObject.Write();
	
EndProcedure

// Gets the "mobile app Versions" directory group corresponding to the specified app.
//
// Parameters:
//  MobileAppName - String - name of the mobile app to get the group for.
//
// Returns:
//  CatalogRef.MobileApplicationsVersions - the directory group corresponding to the mobile application. If not found
//                                         , an empty link is returned.
//
Function GetAppGroup(MobileAppName) Export

	QueryText = 
	"SELECT ALLOWED
	|	MobileApplicationsVersions.Ref AS Ref
	|FROM
	|	Catalog.MobileApplicationsVersions AS MobileApplicationsVersions
	|WHERE
	|	MobileApplicationsVersions.IsFolder
	|	AND MobileApplicationsVersions.Description = &MobileAppName"
	;
	
	Query = New Query();
	Query.Text = QueryText;
	Query.SetParameter("MobileAppName", MobileAppName);
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		Return Selection.Ref;
	Else	
		Return Catalogs.MobileApplicationsVersions.EmptyRef();
	EndIf;

EndFunction

// Retrieves the "mobile app Versions" reference element corresponding to the specified app version.
//
// Parameters:
//  MobileAppName - String - name of the mobile app to get the item for.
//  MobileApplicationVersion - CatalogRef.MobileApplicationsVersions - version of the mobile app
//                                                                            to get the item for.
//
// Returns:
//  CatalogRef.MobileApplicationsVersions - the directory element corresponding to the specified version of the mobile
//                                               application.If not found, an empty link is returned.
//
Function GetAppElement(MobileAppName, MobileApplicationVersion) Export
	
	QueryText = 
	"SELECT ALLOWED
	|	MobileApplicationsVersions.Ref AS Ref
	|FROM
	|	Catalog.MobileApplicationsVersions AS MobileApplicationsVersions
	|WHERE
	|	(NOT MobileApplicationsVersions.IsFolder)
	|	AND MobileApplicationsVersions.Parent.Description = &MobileAppName
	|	AND MobileApplicationsVersions.Code = &MobileApplicationVersion"
	;
	
	Query = New Query();
	Query.Text = QueryText;
	Query.SetParameter("MobileAppName", MobileAppName);
	Query.SetParameter("MobileApplicationVersion", MobileApplicationVersion);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		Return Selection.Ref;
	Else	
		Return Catalogs.MobileApplicationsVersions.EmptyRef();
	EndIf;

EndFunction

// Loads data about the mobile app version from the configuration layout.
//
// Parameters:
//  TemplateName - String - name of the layout to load from.
//
Procedure DownloadAppVersionFromTemplate(TemplateName) Export

	LoadingDataString = Catalogs.MobileApplicationsVersions.GetXMLDataForAppVersion(TemplateName);
	
	XMLReader = New XMLReader();
	XMLReader.SetString(LoadingDataString);
	
	Try
		
		If XMLReader.Read() Then
			If XMLReader.NodeType = XMLNodeType.StartElement Then
				If XMLReader.Name <> "MobileApplicationVersionData" Then
					MessageText = NStr("vi = 'Lỗi kết nhập ứng dụng di động từ khuôn in';
										|ru = 'Ошибка загрузки мобильного приложения из макета';
										|en = 'An error occurred while importing a mobile application from the template'; fa = 'An error occurred while importing a mobile application from the template';
										|it = 'Errore di caricamento dell''app mobile dal layout';
										|pl = 'Błąd pobierania aplikacji mobilnej! z makiety';
										|tr = 'Şablondan mobil uygulama yüklenirken hata oluştu'");
					CommonClientServer.MessageToUser(MessageText);
					Return;
				EndIf;	
			EndIf;
		Else
			MessageText = NStr("vi = 'Lỗi kết nhập ứng dụng di động từ khuôn in';
								|ru = 'Ошибка загрузки мобильного приложения из макета';
								|en = 'An error occurred while importing a mobile application from the template'; fa = 'An error occurred while importing a mobile application from the template';
								|it = 'Errore di caricamento dell''app mobile dal layout';
								|pl = 'Błąd pobierania aplikacji mobilnej! z makiety';
								|tr = 'Şablondan mobil uygulama yüklenirken hata oluştu'");
			CommonClientServer.MessageToUser(MessageText);
			Return;
		EndIf;	
		
		CurrentItemName = Undefined;

		ApplicationName = Undefined;
		VersionNumber = Undefined;
		Application = Undefined;
		UsedMetadata = Undefined;
		
		While XMLReader.Read() Do
			
			If XMLReader.NodeType = XMLNodeType.StartElement Then
				CurrentItemName = XMLReader.Name;
			ElsIf XMLReader.NodeType = XMLNodeType.Text Then
				
				If CurrentItemName = "ApplicationName" Then
					ApplicationName = XMLReader.Value;
				ElsIf CurrentItemName = "Version" Then
					VersionNumber = XMLReader.Value;
				ElsIf CurrentItemName = "Application" Then
					Application = XMLReader.Value;
				ElsIf CurrentItemName = "Metadata" Then
					UsedMetadata = XMLReader.Value;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		ApplicationStructure = ApplicationDescription(ApplicationName, VersionNumber);
		WriteApp(ApplicationName, VersionNumber, Application, UsedMetadata, ApplicationStructure);
		
	Except
		
		MessageText = NStr("vi = 'Lỗi kết nhập ứng dụng di động từ khuôn in';
							|ru = 'Ошибка загрузки мобильного приложения из макета';
							|en = 'An error occurred while importing a mobile application from the template'; fa = 'An error occurred while importing a mobile application from the template';
							|it = 'Errore di caricamento dell''app mobile dal layout';
							|pl = 'Błąd pobierania aplikacji mobilnej! z makiety';
							|tr = 'Şablondan mobil uygulama yüklenirken hata oluştu'");
		CommonClientServer.MessageToUser(MessageText);
		
	EndTry;
	
	XMLReader.Close();

EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForWorkingWithExchangeNodes

// Gets the exchange node corresponding to the mobile connection (i.e., the user + computer pair).
//
// Parameters:
//  UserName - String - the name of the mobile user
//  MobileComputerCode - String - code (serial number or network name) of the mobile computer).
//
// Returns:
//  ExchangePlanRef - Exchange node - a link to the corresponding exchange node.
//
Function GetExchangeNodeForMobileConnection(UserName, MobileComputerCode) Export

	QueryText = 
	"SELECT ALLOWED
	|	SalesRepresentativeMobileApplication.Ref AS Ref
	|FROM
	|	ExchangePlan.SalesRepresentativeMobileApplication AS SalesRepresentativeMobileApplication
	|WHERE
	|	SalesRepresentativeMobileApplication.UserName = &UserName
	|	AND SalesRepresentativeMobileApplication.MobileDevice.SerialNumber = &MobileComputerCode
	|	AND SalesRepresentativeMobileApplication.Ref <> &ThisNode"
	;
	
	Query = New Query();
	Query.Text = QueryText;
	Query.SetParameter("UserName", UserName);
	Query.SetParameter("MobileComputerCode", MobileComputerCode);
	Query.SetParameter("ThisNode", ExchangePlans.SalesRepresentativeMobileApplication.ThisNode());
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		Return Selection.Ref;
	Else	
		Return ExchangePlans.SalesRepresentativeMobileApplication.EmptyRef();
	EndIf;

EndFunction

// Checks whether the node corresponding to the specified connection exists.
//
// Parameters:
//  User - CatalogRef.Users - the user that the node is defined for.
//  MobileDevice - CatalogRef.MobileDevices - a mobile computer that is determined to have a node.
//  NodeUnderReview - ExchangePlanRef - link to the exchange plan node that is being checked for existence.
//
// Returns:
//  Boolean - the existence of a node. True - the node exists, False - does not exist.
//
Function NodeToConnectToExists(User, MobileDevice, NodeUnderReview) Export
	
	QueryText = 
	"SELECT ALLOWED
	|	SalesRepresentativeMobileApplication.Ref AS Ref
	|FROM
	|	ExchangePlan.SalesRepresentativeMobileApplication AS SalesRepresentativeMobileApplication
	|WHERE
	|	SalesRepresentativeMobileApplication.User = &User
	|	AND SalesRepresentativeMobileApplication.MobileDevice = &MobileDevice
	|	AND SalesRepresentativeMobileApplication.Ref <> &ThisNode
	|	AND SalesRepresentativeMobileApplication.Ref <> &NodeUnderReview"
	;
	
	Query = New Query();
	Query.Text = QueryText;
	Query.SetParameter("User", User);
	Query.SetParameter("MobileDevice", MobileDevice);
	Query.SetParameter("ThisNode", ExchangePlans.SalesRepresentativeMobileApplication.ThisNode());
	Query.SetParameter("NodeUnderReview", NodeUnderReview);
	
	Return Not Query.Execute().IsEmpty();

EndFunction

#EndRegion

#Region ExchangePackageFormationProceduresAndFunctions

// Prepares the necessary data for exchange.
//
// Parameters:
//  ExchangeNode - ExchangePlanRef - exchange plan node that requires data preparation.
//  StructureOfDataExchangeParameters - Structure - a structure containing data exchange parameters.
//
Procedure PrepareData(ExchangeNode, StructureOfDataExchangeParameters) Export
	
	UsingTasks = Constants.UseJobsToSalesRepresentatives.Get();
	If UsingTasks = Enums.UseJobsToSalesRepresentatives.UsedBySalesRepresentativesForPlanning Then
		
		If StructureOfDataExchangeParameters.Property("GenerateTasksAutomaticallyBasedOnTermsOfService") Then
			
			GenerateTasks = StructureOfDataExchangeParameters.GenerateTasksAutomaticallyBasedOnTermsOfService;
			If GenerateTasks Then
				
				StartOfPlanningPeriod = '00010101000000';
				EndOfPlanningPeriod = '00010101000000';
				
				If StructureOfDataExchangeParameters.Property("StartOfPlanningPeriod") Then
					StartOfPlanningPeriod = StructureOfDataExchangeParameters.StartOfPlanningPeriod;
				EndIf;
				
				If StructureOfDataExchangeParameters.Property("EndOfPlanningPeriod") Then
					EndOfPlanningPeriod = StructureOfDataExchangeParameters.EndOfPlanningPeriod;
				EndIf;
				
				User = Common.ObjectAttributeValue(ExchangeNode, "User");
				SalesRepresentativesServer.GenerateJobs(User, StartOfPlanningPeriod, EndOfPlanningPeriod);

			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

// Writes data to the exchange packet
//
// Parameters:
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication - the exchange plan node to register the data change for.
//  StructureOfDataExchangeParameters - Structure - a structure containing data exchange parameters.
//  InitialIBInitialization - Boolean - indicates whether the initial initialization of the is is performed.
//
// Returns:
//  String - a string containing the data of the exchange package.
//
Function GenerateExchangeBatch(ExchangeNode, StructureOfDataExchangeParameters, InitialIBInitialization) Export

	XMLWriter = New XMLWriter();
	
	XMLWriter.SetString("UTF-8");
	XMLWriter.WriteXMLDeclaration();
	XMLWriter.WriteStartElement("_1CV8MobileAppData", "http://www.1c.ru/V8/1CV8MobileAppData/");
	XMLWriter.WriteNamespaceMapping("V8MobileAppExch", "http://www.1c.ru/V8/1CV8MobileAppData/");
	XMLWriter.WriteNamespaceMapping("xsi", "http://www.w3.org/2001/XMLSchema-instance");
	XMLWriter.WriteNamespaceMapping("v8",  "http://v8.1c.ru/data");
	
	WriteMessage1 = ExchangePlans.CreateMessageWriter();
	
	TemporaryXMLEntry = New XMLWriter();
	TemporaryXMLEntry.SetString();
	WriteMessage1.BeginWrite(TemporaryXMLEntry, ExchangeNode);
	
	// The data cleaning section is placed at the beginning of the exchange package
	If Not InitialIBInitialization Then
		WriteDataCleanupSection(ExchangeNode, XMLWriter, StructureOfDataExchangeParameters);
	EndIf;
	
	// Next, we place the stored data section
	WriteSectionOfStoredData(ExchangeNode, XMLWriter, StructureOfDataExchangeParameters);
	
	TreeOfMetadataUsed = UsedMetadata(Common.ObjectAttributeValue(ExchangeNode, "MobileApplicationVersion.UsedMetadata"));
	
	// All data satisfying the exchange scheme is selected
	MetadataOfExchangePlan = ExchangeNode.Metadata();
	
	StructureOfSelectionSettings = Filter_Settings(ExchangeNode);
	StructureOfExchangeSettings = DescriptionOfExchangeSettings(ExchangeNode);
	
	For Each ExchangePlanContentItem In MetadataOfExchangePlan.Content Do

		MetadataObject = ExchangePlanContentItem.Metadata;
		
		ObjectDescriptionStructure_ = DataExchangeWithMobileApplicationsEvents.ObjectDetails(MetadataObject, True);

		If ObjectDescriptionStructure_.ClassName = "Catalogs" Or ObjectDescriptionStructure_.ClassName = "Documents" Then
			CompositionStructure = ItemDescription_(MetadataObject, ObjectDescriptionStructure_.ClassName, ObjectDescriptionStructure_.ObjectName, TreeOfMetadataUsed);
		Else
			CompositionStructure = Undefined;
		EndIf;
				
		If Not IncludeDataInExchangePackage(ObjectDescriptionStructure_, StructureOfDataExchangeParameters) Then
			Continue;
		EndIf;
			
		If ObjectDescriptionStructure_.ClassName = "InformationRegisters" Then

			KeyFieldsArray = KeyFieldsOfInformationRegister(MetadataObject);
			FieldArray = InformationRegisterFieldsForSelection(MetadataObject);
			
			// It is necessary to put the message number in the change tables for the subsequent deletion of the registration of changes.
			ExchangePlans.SelectChanges(ExchangeNode, WriteMessage1.MessageNo, MetadataObject);

			// We form a table of values containing all combinations of key register fields for which there are changes.
			KeyTable_ = RecordsetKeys(ObjectDescriptionStructure_, StructureOfSelectionSettings, KeyFieldsArray, StructureOfExchangeSettings, True, ExchangeNode, WriteMessage1.MessageNo);

			SelectedFieldsArray = New Array();
			For Each Column In KeyTable_.Columns Do
				SelectedFieldsArray.Add(Column.Name);
			EndDo;
			
			ObjectDescriptionStructure_ = DataExchangeWithMobileApplicationsEvents.ObjectDetails(MetadataObject, False);
			RecordsTable = InformationRegisterEntries(ObjectDescriptionStructure_, StructureOfSelectionSettings, FieldArray, StructureOfExchangeSettings, ExchangeNode);

			FilterStructure1 = New Structure();

			For Each KeyCombination In KeyTable_ Do

				For Each KeyField In KeyFieldsArray Do
					If SelectedFieldsArray.Find(KeyField) <> Undefined Then
						FilterStructure1.Insert(KeyField, KeyCombination[KeyField]);
					EndIf;
				EndDo;

				ArrayOfRecordTableRows = RecordsTable.FindRows(FilterStructure1);
				RecordSet = CreateSetOfRecordsToUpload(ObjectDescriptionStructure_.ObjectName, KeyCombination, ArrayOfRecordTableRows, KeyFieldsArray, FieldArray, SelectedFieldsArray);
				WriteDataToExchangePacket(RecordSet, ObjectDescriptionStructure_.ClassName, ObjectDescriptionStructure_.ObjectName, CompositionStructure, XMLWriter, ExchangeNode);

			EndDo;

		Else
			
			// We write the data of constants, reference books and documents directly from the sample in XML
			DataSelection = ExchangePlans.SelectChanges(ExchangeNode, WriteMessage1.MessageNo, MetadataObject);
			
			While DataSelection.Next() Do
				Object = DataSelection.Get();
				ProcessObjectBeforeWritingToExchangePacket(Object, ObjectDescriptionStructure_.ClassName, ObjectDescriptionStructure_.ObjectName, 
					StructureOfDataExchangeParameters, ExchangeNode);
				WriteDataToExchangePacket(Object, ObjectDescriptionStructure_.ClassName, ObjectDescriptionStructure_.ObjectName, CompositionStructure, XMLWriter, ExchangeNode);
			EndDo;
			
		EndIf;
		
	EndDo;

	WriteMessage1.EndWrite();
	
	XMLWriter.WriteEndElement(); //_1CV8MobileAppData
	
	Return XMLWriter.Close();

EndFunction

#EndRegion

#Region ProceduresAndFunctionsOfWorkingWithReceivedExchangePackets

// Writes the data contained in the received exchange packet to the is.
//
// Parameters:
//  ExchangeNode - ExchangePlanRef - the exchange plan node that the received exchange packet is intended for.
//  MobileApplicationData - String - exchange packet as an xml string.
//  DataExchangeParameters - String - A string with data exchange parameters.
//
Procedure RecordDataOfReceivedExchangePacket(ExchangeNode, MobileApplicationData, DataExchangeParameters) Export
	
	XMLReader = New XMLReader;
	XMLReader.SetString(MobileApplicationData);
	
	// checking the exchange file format
	If Not XMLReader.Read() Or
		XMLReader.NodeType <> XMLNodeType.StartElement Or 
		XMLReader.LocalName <> "_1CV8MobileAppData" Or 
		XMLReader.NamespaceURI <> "http://www.1c.ru/V8/1CV8MobileAppData/" Then
		
		#If ExternalConnection Then
		MessageText = NStr("vi = 'Sai định dạng dữ liệu: đầu tệp không chính xác';
							|ru = 'Неверный формат данных: некорректное начало файла';
							|en = 'Incorrect data format: incorrect file start'; fa = 'Incorrect data format: incorrect file start';
							|it = 'Formato dati non valido: inizio file non corretto';
							|pl = 'Błędny format danych: niepoprawne rozpoczęcie pliku';
							|tr = 'Yanlış veri formatı: yanlış dosya başlangıcı'");
		Raise(MessageText);
		#EndIf
	
		Return;
		
	EndIf;

	StructureOfDescriptionOfObjectsUsed = DescriptionOfObjectsUsed(ExchangeNode);

	// reading and writing of the exchange packet data to the IB
	If Not XMLReader.Read() Then
		Return;
	EndIf;
	
	MetadataOfExchangePlan = ExchangeNode.Metadata();
	
	StructureOfExchangeSettings = DescriptionOfExchangeSettings(ExchangeNode);
	StructureOfDataExchangeParameters = DescriptionOfDataExchangeParameters(DataExchangeParameters);

	While CanReadXML(XMLReader) Do
		
		XMLType = GetXMLType(XMLReader);

		If XMLType = Undefined Then
			XMLReader.Skip();
			Continue;
		EndIf; 
		
		ClassName = "";
		ObjectName = "";
		DefineClassAndTypeNameByDataType(XMLType.TypeName, ClassName, ObjectName);
		
		// directly reading the data itself
		ReadObject_ = Undefined;
		
		If ClassName = "CATALOGOBJECT" Then

			// reading the directory element
			ObjectComposition = StructureOfDescriptionOfObjectsUsed["Catalogs" + ObjectName];
			ReadObject_ = ReadAndEditCatalogItem(XMLReader, ObjectName, ObjectComposition, ExchangeNode);

			ProcessFillingInNewObject(ReadObject_, "Catalogs", ObjectName, ExchangeNode);

		ElsIf ClassName = "DOCUMENTOBJECT" Then

			// reading the document
			ObjectComposition = StructureOfDescriptionOfObjectsUsed["Documents" + ObjectName];
			ReadObject_ = ReadAndModifyDocument(XMLReader, ObjectName, ObjectComposition, ExchangeNode);

			ProcessFillingInNewObject(ReadObject_, "Documents", ObjectName, ExchangeNode);

		Else
			// Constants and sets of data register entries can be read without additional analysis,
			// since these values are presented holistically in the exchange package.
			ReadObject_ = ReadXML(XMLReader);

		EndIf;
		
		// there's nothing to write down when you haven't read anything
		If ReadObject_ = Undefined Then
			Continue;
		EndIf;
		
		If ExchangePlans.IsChangeRecorded(ExchangeNode, ReadObject_) Then
			// Changes made in the central information system should not be overwritten by changes in the mobile information system.
			Continue;
		EndIf;
		
		ReadObject_.DataExchange.Load = True;
		
		If MetadataOfExchangePlan.Content.Contains(ReadObject_.Metadata()) Then
			If Not YouNeedToRegisterChangesForSenderNode(ClassName, ObjectName, ReadObject_) Then
				ReadObject_.DataExchange.Sender = ExchangeNode;
			EndIf;
		EndIf;
		
		ReadObject_.Write();
		
		ProcessRecordedObject(ReadObject_, StructureOfExchangeSettings, ExchangeNode);

	EndDo;

	XMLReader.Close();

EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForManagingChangeLoggingAndDataSampling

// Determines whether changes should be registered in the specified exchange plan node based on the
// exchange scheme defined for this exchange node.
//
// Parameters:
//  ObjectAttributeStructure - Structure - structure containing the details of the object being checked.
//  ObjectDescriptionStructure_ - Structure - a structure containing a description of the metadata object.
//  FieldArray - Array - an array containing the names of the object's fields.
//  ObjectDataTable - ValueTable - a table of values containing data from the object's fields.
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication - the exchange plan node where changes are registered.
//
// Returns:
//  Boolean - A sign of the need to register changes for the object. True - registration is required. False - registration
//                                                                            is not required.
//
Function RegistrationOfObjectChangesIsRequired(ObjectAttributeStructure, ObjectDescriptionStructure_, FieldArray, ObjectDataTable, ExchangeNode) Export

	ClassName = ObjectDescriptionStructure_.ClassName;
	ObjectName = ObjectDescriptionStructure_.ObjectName;
	
	StructureOfExchangeSettings = DescriptionOfExchangeSettings(ExchangeNode);
	
	StructureOfSelectionSettings = Filter_Settings(ExchangeNode);
	
	If ObjectUsageDisabled(ClassName, ObjectName, ExchangeNode) Then
		Return False;
	EndIf;
	
	CompositionSchema = GetDataLayoutDiagramForObject(FieldArray);
	CompositionSettings = ComposeSettings(CompositionSchema);
	
	AddSelectionsFromExchangeScheme(CompositionSettings, StructureOfSelectionSettings, ClassName, ObjectName, False, StructureOfExchangeSettings, False);
	AddSelectionsForIndividualObjects(ObjectAttributeStructure, CompositionSettings.Filter, StructureOfSelectionSettings, ClassName, ObjectName);
	AddMandatorySelections(CompositionSettings, ClassName, ObjectName, StructureOfExchangeSettings);
	
	CompositionTemplate = DataCompositionServer.GetLayoutTemplate(CompositionSchema, CompositionSettings);
	
	ExternalDataSets = New Structure("DataObject", ObjectDataTable);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor();
	ResultTable2 = OutputProcessor.Output(CompositionProcessor);
	
	Return ResultTable2.Count()>0;

EndFunction

// Registers changes for the specified exchange node according
// to the exchange scheme defined for this node.
//
// Parameters:
// ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication - the exchange plan node to register changes for.
//
Procedure RecordDataChanges(ExchangeNode) Export

	ExchangePlanContent = ExchangeNode.Metadata().Content;
	
	StructureOfExchangeSettings = DescriptionOfExchangeSettings(ExchangeNode);
	
	StructureOfSelectionSettings = Filter_Settings(ExchangeNode);
	
	// In the loop, all metadata objects that are part of the exchange plan are bypassed and
	// changes are registered for each of them, taking into account the settings of the exchange scheme.

	For Each ExchangePlanContentItem In ExchangePlanContent Do
		
		ObjectDescriptionStructure_ = DataExchangeWithMobileApplicationsEvents.ObjectDetails(ExchangePlanContentItem.Metadata, False);

		ClassName = ObjectDescriptionStructure_.ClassName;
		ObjectName = ObjectDescriptionStructure_.ObjectName;
	
		If ClassName = "Constants" Then
			
			// No selection conditions are set for constants, so we will register the changes immediately.
			ExchangePlans.RecordChanges(ExchangeNode,ExchangePlanContentItem.Metadata);

		ElsIf ClassName = "Catalogs" Or ClassName = "Documents" Then
			
			If ObjectUsageDisabled(ClassName, ObjectName, ExchangeNode) Then
				Continue;
			EndIf;	
			
			// For reference books and documents, we will select the links by which we will register the changes.
			DataSelection = SelectLinksToRegisterChanges(ExchangeNode, ObjectDescriptionStructure_, StructureOfSelectionSettings, StructureOfExchangeSettings);
			
			While DataSelection.Next() Do
				
				ExchangePlans.RecordChanges(ExchangeNode,DataSelection.Ref);
				
			EndDo;
			
		ElsIf ClassName = "InformationRegisters" Then
			
			FieldArray = KeyFieldsOfInformationRegister(ExchangePlanContentItem.Metadata);
			KeyTable_ = RecordsetKeys(ObjectDescriptionStructure_, StructureOfSelectionSettings, FieldArray, StructureOfExchangeSettings);
			
			SelectedFieldsArray = New Array();
			For Each Column In KeyTable_.Columns Do
				SelectedFieldsArray.Add(Column.Name);
			EndDo;

			// For each unique combination of fields, we will form sets of records with such selections and register changes for them.
			For Each KeyCombination In KeyTable_ Do

				RecordSet = GetSetOfInformationRegisterRecordsByKeyCombination(ObjectDescriptionStructure_, KeyCombination, FieldArray, SelectedFieldsArray);
				ExchangePlans.RecordChanges(ExchangeNode,RecordSet);

			EndDo;
			
		EndIf;
		
	EndDo;

EndProcedure

// Generates and returns the query text for selecting data from a specific data register.
//
// Parameters:
//  ObjectName - String - name of the register to use for generating the request text.
//  TableName - String - name of the data table to use for generating the query text.
//  FieldArray - Array - an array containing the names of the fields to be selected.
//  Changes - Boolean - indicates whether only changes are selected.
//  MessageNo - Number - number of the exchange message.
//
// Returns:
//  String - The text of the request, if it is defined for the register. Otherwise, an empty string is returned - the
//  "standard" query text for the table will be used, without additional conditions.
//
Function GetRequestTextForRegister(ObjectName, TableName, FieldArray, Changes, MessageNo) Export
	
	QueryText = "";
	
	If TableName = "InformationRegister.RelativeExchangeRates" Then
				
		QueryText =
		"SELECT ALLOWED
		|	CurrencyRatesCut.Period,
		|	CurrencyRatesCut.Currency,
		|	CurrencyRatesCut.BaseCurrency,
		|	CurrencyRatesCut.CourseNumerator,
		|	CurrencyRatesCut.CourseDenominator
		|FROM
		|	InformationRegister.RelativeExchangeRates.SliceLast(&CurrentDate, ) AS CurrencyRatesCut"
		;
	EndIf;
	
	If Changes Then
		ArrayOfSelectionFields_ = New Array();
		ArrayOfSelectionFields_.Add("Node");
		
		If MessageNo <> Undefined Then
			ArrayOfSelectionFields_.Add("MessageNo");
		EndIf;	
	Else
		ArrayOfSelectionFields_ = DataExchangeWithMobileApplicationsEvents.SelectionFieldsForObject("InformationRegisters", ObjectName);
	EndIf;
	
	AddSelectionFieldsToQueryText(QueryText, ArrayOfSelectionFields_);
	
	Return QueryText;

EndFunction

#EndRegion

#Region ProceduresAndFunctionsForWorkingWithDataLayout

// Generates and returns linker settings for the passed layout scheme.
//
// Parameters:
//  CompositionSchema - DataCompositionSchema - data layout scheme for which settings are compiled.
//
// Returns:
//  DataCompositionSettings - the settings of the linker.
//
Function ComposeSettings(CompositionSchema) Export

	SettingsSource = New DataCompositionAvailableSettingsSource(CompositionSchema);
	SettingsComposer = New DataCompositionSettingsComposer();
	SettingsComposer.Initialize(SettingsSource);
	
	// Add the selected fields
	For Each Item In SettingsComposer.Settings.Selection.SelectionAvailableFields.Items Do
		
		If Not Item.Folder Then
			SelectedField = SettingsComposer.Settings.Selection.Items.Add(Type("DataCompositionSelectedField"));
			SelectedField.Use = True;
			SelectedField.Field = Item.Field;
		EndIf;
		
	EndDo;
	
	// Adding a grouping
	GroupingSettings = SettingsComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
	Field = GroupingSettings.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	
	Return SettingsComposer.Settings;

EndFunction

// Adds a selection element to the layout settings
//
// Parameters:
//  Settings - DataCompositionSettings - layout settings
//  FieldName - String - name of the field to select from
//  Var_ComparisonType - DataCompositionComparisonType - data layout comparison view
//  Use - Boolean - using the selection element
//  RightValue - Arbitrary - the right comparison value.
//
Procedure AddSelectionElementToSchemaSettings(Settings, FieldName, Var_ComparisonType = Undefined, Use = True, RightValue = Undefined) Export

	If Var_ComparisonType = Undefined Then
		Var_ComparisonType = DataCompositionComparisonType.Equal;
	EndIf;

	Field = New DataCompositionField(FieldName);
	Item = Settings.FilterAvailableFields.FindField(Field);

	If Item = Undefined Then
		Return;
	EndIf;

	FilterElement = Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	
	FilterElement.LeftValue = Item.Field;
	FilterElement.ComparisonType = Var_ComparisonType;
	FilterElement.Use = Use;
	FilterElement.RightValue = RightValue;

EndProcedure

// Sets the value of the selection element in the layout settings
//
// Parameters:
//  Filter - DataCompositionFilter - selecting the layout.
//  FieldName - String - field name.
//  Var_ComparisonType - DataCompositionComparisonType - type of comparison.
//  Use - Boolean - signs of use.
//  RightValue - Arbitrary - the right value in the selection.
//
Procedure SetFilterItemValue(Filter, FieldName, Var_ComparisonType = Undefined, Use = True, RightValue = Undefined) Export

	If Var_ComparisonType = Undefined Then
		Var_ComparisonType = DataCompositionComparisonType.Equal;
	EndIf;
	
	LayoutField = New DataCompositionField(FieldName);
	
	For Each FilterElement In Filter.Items Do
		
		If FilterElement.LeftValue = LayoutField Then
			FilterElement.RightValue = RightValue;
			FilterElement.Use = Use;
		EndIf;
		
	EndDo;

EndProcedure

// Sets whether to include the field in the layout settings.
//
// Parameters:
//  CompositionSettings - DataCompositionSettings - layout settings for which you want to set usage.
//  FieldName - String - name of the layout field to use.
//  Use - Boolean - indicates whether the field is being used.
//
Procedure SetUseOfLayoutField(CompositionSettings, FieldName, Use) Export

	LayoutField = New DataCompositionField(FieldName);

	For Each Item In CompositionSettings.Selection.Items Do
		If TypeOf(Item) = Type("DataCompositionSelectedField") Then
			If Item.Field = LayoutField Then
				Item.Use = Use;
			EndIf;
		EndIf;
	EndDo;

EndProcedure

// Sets the specified value for the data layout settings parameter.
//
// Parameters:
//  Settings - DataCompositionSettings - Customize the layout of the data.
//  ParameterName - String - the name of the parameter whose value you want to set.
//  Value - Arbitrary - the parameter value to set.
//
Procedure SetValueOfSettingsParameter(Settings, ParameterName, Value) Export

	Parameter = Settings.DataParameters.Items.Find(ParameterName);
	
	If Parameter <> Undefined Then
		Parameter.Value = Value;
		Parameter.Use = True;
	EndIf;

EndProcedure

// Generates and returns a structure based on the passed data layout selection.
//
// Parameters:
//  Filter - DataCompositionFilter - selecting the data layout.
//
// Returns:
//  Structure - the structure containing the selection data.
// 
Function DescriptionOfDataLayoutSelection(Filter) Export

	FilterStructure1 = New Structure();
	
	For Each FilterElement In Filter.Items Do
		
		// Fill in the structure of the selection element
		StructureOfSelectionElement = New Structure();
		
		If TypeOf(FilterElement) = Type("DataCompositionFilterItem") Then
			
			StructureOfSelectionElement.Insert("ComparisonType",FilterElement.ComparisonType);
			StructureOfSelectionElement.Insert("UserSettingID",FilterElement.UserSettingID);
			StructureOfSelectionElement.Insert("Use",FilterElement.Use);
			StructureOfSelectionElement.Insert("LeftValue",FilterElement.LeftValue);
			StructureOfSelectionElement.Insert("RightValue",FilterElement.RightValue);
			StructureOfSelectionElement.Insert("Presentation",FilterElement.Presentation);
			StructureOfSelectionElement.Insert("UserSettingPresentation",FilterElement.UserSettingPresentation);
			StructureOfSelectionElement.Insert("Application",FilterElement.Application);
			StructureOfSelectionElement.Insert("ViewMode",FilterElement.ViewMode);
			
			// The structure of the selection element will be placed in the selection structure
			FilterStructure1.Insert(FilterElement.LeftValue, StructureOfSelectionElement);
		EndIf;
		
	EndDo;
	
	Return FilterStructure1;

EndFunction

// Fills in the specified selection based on the structure containing the selection data.
//
// Parameters:
//  Filter - DataCompositionFilter - selecting the data layout to fill in.
//  FilterStructure1 - Structure - the structure containing the data to fill in the selection.
//
Procedure CompleteLayoutSelectionFromStructure(Filter, FilterStructure1) Export

	Filter.Items.Clear();
	
	For Each ElementOfSelectionStructure In FilterStructure1 Do
		
		FilterElement = Filter.Items.Add(Type("DataCompositionFilterItem"));
		
		StructureOfSelectionElement = ElementOfSelectionStructure.Value;
		
		For Each Item In StructureOfSelectionElement Do
			If Item.Key = "LeftValue" Then
				FilterElement[Item.Key] =  New DataCompositionField(Item.Value);
			Else
				FilterElement[Item.Key] = Item.Value;
			EndIf;
		EndDo;	
		
	EndDo;

EndProcedure

// Sets selections for selecting objects using the layout.
//
// Parameters:
//  CompositionSettings - DataCompositionSettings - customize the layout data for which to set the selection.
//  StructureOfSelectionSettings - Structure - a structure containing a description of the selection to be set.
//  ClassName - String - name of the class that the object belongs to (reference Books, Documents, etc.).
//  ObjectName - String - the name of the metadata object to which are added selections.
//  UseAdditionalSelections - Boolean - indicates whether additional selections should be set for registers (in addition
//                                              to key fields).
//  StructureOfExchangeSettings - Structure - structure that contains the configuration settings of exchange.
//  SelectionIsUsed - Boolean - indicates that a data selection is being used and selections are specified for the selection.
//
Procedure AddSelectionsFromExchangeScheme(CompositionSettings, StructureOfSelectionSettings, ClassName, ObjectName, 
									  UseAdditionalSelections, StructureOfExchangeSettings, SelectionIsUsed) Export

	If ClassName = "Catalogs" Then

		If ObjectName = "Partners" Then
			FillInLayoutSelectionElementFromStructure(CompositionSettings.Filter, StructureOfSelectionSettings, "Partners","Ref");
		ElsIf ObjectName = "Counterparties" Then
			FillInLayoutSelectionElementFromStructure(CompositionSettings.Filter, StructureOfSelectionSettings, "Partners","Partner");
		ElsIf ObjectName = "ContactPersonsForPartners" Then
			FillInLayoutSelectionElementFromStructure(CompositionSettings.Filter, StructureOfSelectionSettings, "Partners","Owner");
			AddSelectionElementToSchemaSettings(CompositionSettings, "Owner.ServedBySalesRepresentatives", DataCompositionComparisonType.Equal, True, True);
		ElsIf ObjectName = "Companies" Then
			FillInLayoutSelectionElementFromStructure(CompositionSettings.Filter, StructureOfSelectionSettings, "Companies","Ref");
		ElsIf ObjectName = "TermsOfSale" Then
			If SelectionIsUsed Then
				FillInLayoutSelectionElementFromStructure(CompositionSettings.Filter, StructureOfSelectionSettings, "Partners","Partner");
			EndIf;
		ElsIf ObjectName = "CounterpartyContracts" Then
			If SelectionIsUsed Then
				FillInLayoutSelectionElementFromStructure(CompositionSettings.Filter, StructureOfSelectionSettings, "Partners","Partner");
			EndIf;
		ElsIf ObjectName = "Products" Then
			FillInLayoutSelectionElementFromStructure(CompositionSettings.Filter, StructureOfSelectionSettings, "Products","Ref");
		ElsIf ObjectName = "ProductPackages" Then
			If SelectionIsUsed Then
				FillInLayoutSelectionElementFromStructure(CompositionSettings.Filter, StructureOfSelectionSettings, "Products","Owner");
			EndIf;
		ElsIf ObjectName = "ItemsCharacteristics" Then
			If SelectionIsUsed Then
				FillInLayoutSelectionElementFromStructure(CompositionSettings.Filter, StructureOfSelectionSettings, "Products","Owner");
			EndIf;
		ElsIf ObjectName = "TypesOfPrices" Then
			FillInLayoutSelectionElementFromStructure(CompositionSettings.Filter, StructureOfSelectionSettings, "TypesOfPrices","Ref");
		ElsIf ObjectName = "Warehouses" Then
			FillInLayoutSelectionElementFromStructure(CompositionSettings.Filter, StructureOfSelectionSettings, "Warehouses","Ref");
		ElsIf ObjectName = "ReasonsForSaleOrderCancellation" Then
			FillInLayoutSelectionElementFromStructure(CompositionSettings.Filter, StructureOfSelectionSettings, "ReasonsForSaleOrderCancellation","Ref");
		ElsIf ObjectName = "ProductsAttachedFiles" Then
			FillInLayoutSelectionElementFromStructure(CompositionSettings.Filter, StructureOfSelectionSettings, "Products","Ref");
		EndIf;

	ElsIf ClassName = "Documents" Then

		If ObjectName = "JobForSalesRepresentative" Then
			FillInLayoutSelectionElementFromStructure(CompositionSettings.Filter, StructureOfSelectionSettings, "Partners","Partner");
		EndIf;

	ElsIf ClassName = "InformationRegisters" Then

		If ObjectName = "ItemsPrices" Then
			If UseAdditionalSelections Then
				FillInLayoutSelectionElementFromStructure(CompositionSettings.Filter, StructureOfSelectionSettings, "TypesOfPrices","PriceKind");
				FillInLayoutSelectionElementFromStructure(CompositionSettings.Filter, StructureOfSelectionSettings, "Products","Products");
				AddSelectionElementToSchemaSettings(CompositionSettings, "PriceKind.UseWhileSellingToCustomers", DataCompositionComparisonType.Equal, True, True);
			EndIf;
		ElsIf ObjectName = "GoodsAvailabilityForExternalUsers" Then
			If UseAdditionalSelections Then
				FillInLayoutSelectionElementFromStructure(CompositionSettings.Filter, StructureOfSelectionSettings, "Products","Products");
				FillInLayoutSelectionElementFromStructure(CompositionSettings.Filter, StructureOfSelectionSettings, "Warehouses","Warehouse");
			EndIf;
		EndIf;

	EndIf;

EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForWorkingWithExchangeSettingsAndParameters

// Generates and returns a structure containing the selection settings structures.
//
// Parameters:
//  ExchangeNode - ExchangePlanRef - the site plan of exchange, which are determined by the setup selections.
//
// Returns:
//  Structure - a structure describing the selections.
//
Function Filter_Settings(ExchangeNode) Export
	
	StorageOfExchangeSchemeFilter = Common.ObjectAttributeValue(ExchangeNode, "StorageOfExchangeSchemeFilter");
	SettingsStructure = StorageOfExchangeSchemeFilter.Get();
	
	If TypeOf(SettingsStructure) = Type("Structure") Then
		Return SettingsStructure;
	Else
		Return New Structure();
	EndIf;
	
	Return SettingsStructure;

EndFunction

// Generates and returns a structure that describes the exchange settings for the specified exchange node.
//
// Parameters:
//  ExchangeNode - ExchangePlanRef - the exchange plan node that you want to get parameters for.
//
// Returns:
//  Structure - a structure describing the exchange settings for the specified exchange node, with the fields:
//      * AutomaticallyCreateOrdersForJob - Boolean - indicates whether orders should be created automatically.
//      * SalesRepresentative - CatalogRef.Users - sales representative.
//      * UseContactDetails - EnumRef.ContactDetailsUsageByMobileApplication -
//                                            type of use of contact information.
//      * UseTermsOfSales - EnumRef.UseTermsOfSales - type of use
//          of agreements with clients.
//
Function DescriptionOfExchangeSettings(ExchangeNode) Export
	
	AutomaticallyCreateOrdersForJob = False;
	SalesRepresentative = Undefined;
	UseContactDetails = Undefined;
	
	QueryText =
	"SELECT ALLOWED
	|	SalesRepresentativeMobileApplication.User AS SalesRepresentative,
	|	SalesRepresentativeMobileApplication.AutomaticallyCreateOrdersForJob AS AutomaticallyCreateOrdersForJob,
	|	SalesRepresentativeMobileApplication.UseContactDetails AS UseContactDetails
	|FROM
	|	ExchangePlan.SalesRepresentativeMobileApplication AS SalesRepresentativeMobileApplication
	|WHERE
	|	SalesRepresentativeMobileApplication.Ref = &ExchangeNode"
	;
	
	Query = New Query(QueryText);
	Query.SetParameter("ExchangeNode", ExchangeNode);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		AutomaticallyCreateOrdersForJob = Selection.AutomaticallyCreateOrdersForJob;
		SalesRepresentative = Selection.SalesRepresentative;
		UseContactDetails = Selection.UseContactDetails;
		
	EndIf;
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("AutomaticallyCreateOrdersForJob", AutomaticallyCreateOrdersForJob);
	ParametersStructure.Insert("SalesRepresentative", SalesRepresentative);
	ParametersStructure.Insert("UseContactDetails", UseContactDetails);
    ParametersStructure.Insert("UseTermsOfSales", Constants.UseTermsOfSales.Get());
	
	Return ParametersStructure;

EndFunction

// Parses the xml string of data exchange parameters and forms a parameter structure based on it.
//
// Parameters:
//  DataExchangeParameters - String - an xml string containing the parameters of the exchange.
//
// Returns:
//  Structure - a structure containing the exchange parameters.
//
Function DescriptionOfDataExchangeParameters(DataExchangeParameters) Export
	
	ParametersStructure = New Structure();
	
	XMLReader = New XMLReader();
		
	Try
		XMLReader.SetString(DataExchangeParameters);
	Except
		
		#If ExternalConnection Then
		MessageText = NStr("vi = 'Lỗi khi đọc tham số trao đổi dữ liệu:';
							|ru = 'Ошибка при чтении параметров обмена данными:';
							|en = 'An error occurred while reading data exchange parameters:'; fa = 'An error occurred while reading data exchange parameters:';
							|it = 'Errore nella lettura dei parametri di scambio dati:';
							|pl = 'Błąd podczas odczytu parametrów wymiany danych:';
							|tr = 'Vari değişimi parametrelerini okurken hata oluştu:'");
		Raise(MessageText + BriefErrorDescription(ErrorInfo()));
		#EndIf
		
	EndTry;
	
	Try
		
		While XMLReader.Read() Do
			
			While CanReadXML(XMLReader) Do
				
				ParameterName = XMLReader.Name;
				ParameterValue = ReadXML(XMLReader);
				
				ParametersStructure.Insert(ParameterName, ParameterValue);
				
			EndDo;
			
		EndDo;		
				
	Except
		
		#If ExternalConnection Then
		MessageText = NStr("vi = 'Lỗi khi đọc tham số trao đổi dữ liệu:';
							|ru = 'Ошибка при чтении параметров обмена данными:';
							|en = 'An error occurred while reading data exchange parameters:'; fa = 'An error occurred while reading data exchange parameters:';
							|it = 'Errore nella lettura dei parametri di scambio dati:';
							|pl = 'Błąd podczas odczytu parametrów wymiany danych:';
							|tr = 'Vari değişimi parametrelerini okurken hata oluştu:'");
		Raise(MessageText + BriefErrorDescription(ErrorInfo()));
		#EndIf
		
	EndTry;

	Return ParametersStructure;

EndFunction

// Determines whether an external data exchange component needs to be connected at system startup.
//
// Returns:
//  Boolean - the result of the check. True - connection is required, False - not required.
//
Function ConnectDataExchangeComponentOnTheApplicationStart() Export
	
	ConnectionRequired = False;
	
	SettingValueFromStorage = Undefined;
	SettingValueFromStorage = Common.CommonSettingsStorageLoad("UserSettingsForDataExchangeComponent", 
																				"ConnectDataExchangeComponentOnTheApplicationStart");
		
	If SettingValueFromStorage <> Undefined Then
		ConnectionRequired = SettingValueFromStorage;
	EndIf;
	
	Return ConnectionRequired;

EndFunction

#EndRegion

#Region MetadataProceduresAndFunctions

// Generates a tree of used metadata based on the description received from the mobile app editor.
//
// Parameters:
//  MetadataDetails - String - XML string containing a description of the metadata used.
//
// Returns:
//  ValueTree - Tree values - with columns:
//   * Name - String
//   * Use - Boolean
//
Function UsedMetadata(MetadataDetails) Export

	MetadataTree = New ValueTree();
	MetadataTree.Columns.Add("Name");	
	MetadataTree.Columns.Add("Use");	
	
	XMLReader = New XMLReader();
	XMLReader.SetString(MetadataDetails);
	
	TreeRow = Undefined;
	
	Try
		
		While XMLReader.Read() Do	
			
			If XMLReader.NodeType = XMLNodeType.StartElement Then
				
				If TreeRow = Undefined Then
					CollectionOfRowsToAdd = MetadataTree.Rows;
				Else
					CollectionOfRowsToAdd = TreeRow.Rows;
				EndIf;	
					
				TreeRow = CollectionOfRowsToAdd.Add();
				Name = XMLReader.Name;
				TreeRow.Name = Name;
				
				If TreeRow.Level() = 1 Then
					
					If Name = "Constants" Then
						TreeRow.Name = "Constants";
					ElsIf Name = "Catalogs" Then
						TreeRow.Name = "Catalogs";
					ElsIf Name = "Documents" Then
						TreeRow.Name = "Documents";
					ElsIf Name = "InformationRegisters" Then
						TreeRow.Name = "InformationRegisters";
					EndIf;
						
				EndIf;
				
			ElsIf XMLReader.NodeType = XMLNodeType.EndElement Then
				
				If TreeRow <> Undefined Then
					TreeRow = TreeRow.Parent;
				EndIf;	
				
			EndIf;
				
		EndDo;
			
	Except
		
		#If ExternalConnection Then
		Raise(NStr("vi = 'Lỗi đọc bảng kê metadata sử dụng ứng dụng di động';
					|ru = 'Ошибка чтения перечня метаданных, используемых мобильным приложением';
					|en = 'An error occurred while reading metadata list used by the mobile application'; fa = 'An error occurred while reading metadata list used by the mobile application';
					|it = 'Errore di lettura dell''elenco dei metadati utilizzati da un''applicazione mobile';
					|pl = 'Błąd odczytu wykazu metadanych, stosowanych przez aplikację mobilną';
					|tr = 'Mobil uygulama tarafından kullanılan meta veri listesi okunurken hata oluştu'"));
		#EndIf
	
	EndTry;
	
	Return MetadataTree;

EndFunction

#EndRegion

#EndRegion

#Region Private

#Region ExchangePackageFormationProceduresAndFunctions

// Writes a special ClearData section to the exchange packet.
//
// Parameters:
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication - the exchange plan node for which you want to create a data cleanup section.
//  XMLWriter - XMLWriter - the XML record object that is used to record the exchange package.
//  StructureOfDataExchangeParameters - Structure - a structure containing data exchange parameters.
//
Procedure WriteDataCleanupSection(ExchangeNode, XMLWriter, StructureOfDataExchangeParameters)
	
	XMLWriter.WriteStartElement("ClearData");
	
	// Clearing of terminated agreements
	
	XMLWriter.WriteStartElement("Catalog.TermsOfSale");
		XMLWriter.WriteStartElement("Filter");
		
			XMLWriter.WriteStartElement("ValidityEndDate");
				WriteXML(XMLWriter, BegOfDay(CurrentSessionDate()), "Value", XMLTypeAssignment.Implicit);
				WriteXML(XMLWriter, "Less", "ComparisonType", XMLTypeAssignment.Implicit);
			XMLWriter.WriteEndElement(); //For the "End date of action" tag
			
			XMLWriter.WriteStartElement("ValidityEndDate");
				WriteXML(XMLWriter, '00010101000000', "Value", XMLTypeAssignment.Implicit);
				WriteXML(XMLWriter, "NotEqual", "ComparisonType", XMLTypeAssignment.Implicit);
			XMLWriter.WriteEndElement(); //For the "End date of action" tag
			
		XMLWriter.WriteEndElement(); // For the Filter tag
	XMLWriter.WriteEndElement(); // For the tag "Catalog.Agreementsclients"
	
	// Clearing of terminated contracts
	
	XMLWriter.WriteStartElement("Catalog.CounterpartyContracts");
		XMLWriter.WriteStartElement("Filter");
		
			XMLWriter.WriteStartElement("ValidityEndDate");
				WriteXML(XMLWriter, BegOfDay(CurrentSessionDate()), "Value", XMLTypeAssignment.Implicit);
				WriteXML(XMLWriter, "Less", "ComparisonType", XMLTypeAssignment.Implicit);
			XMLWriter.WriteEndElement(); //For the "End date of action" tag
			
			XMLWriter.WriteStartElement("ValidityEndDate");
				WriteXML(XMLWriter, '00010101000000', "Value", XMLTypeAssignment.Implicit);
				WriteXML(XMLWriter, "NotEqual", "ComparisonType", XMLTypeAssignment.Implicit);
			XMLWriter.WriteEndElement(); //For the "End date of action" tag
			
		XMLWriter.WriteEndElement(); // For the Filter tag
	XMLWriter.WriteEndElement(); // For the tag "Catalog.Contractors' agreements"
	
	// Clearing tasks marked for deletion
	
	UsingTasks = Constants.UseJobsToSalesRepresentatives.Get();
	If UsingTasks = Enums.UseJobsToSalesRepresentatives.UsedBySalesRepresentativesForPlanning Then
	
		XMLWriter.WriteStartElement("Document.JobForSalesRepresentative");
			XMLWriter.WriteStartElement("Filter");
			
				XMLWriter.WriteStartElement("DeletionMark");
					WriteXML(XMLWriter, True, "Value", XMLTypeAssignment.Implicit);
					WriteXML(XMLWriter, "Equal", "ComparisonType", XMLTypeAssignment.Implicit);
				XMLWriter.WriteEndElement(); //For the tag "Tag Removal"
				
			XMLWriter.WriteEndElement(); // For the Filter tag
		XMLWriter.WriteEndElement(); // For the tag "Document.Assignment to the Trade representative"
	
	EndIf;
	
	If UsingTasks <> Enums.UseJobsToSalesRepresentatives.NotUsed_ Then
		// Clearing tasks at the user's request
		If StructureOfDataExchangeParameters.Property("DeleteTasks_") And StructureOfDataExchangeParameters.Property("DateWhenTasksWereCleared") Then
			If StructureOfDataExchangeParameters.DeleteTasks_ Then
				XMLWriter.WriteStartElement("Document.JobForSalesRepresentative");
					XMLWriter.WriteStartElement("Filter");
					
						XMLWriter.WriteStartElement("ActualVisitDate");
							WriteXML(XMLWriter, EndOfDay(StructureOfDataExchangeParameters.DateWhenTasksWereCleared), "Value", XMLTypeAssignment.Implicit);
							WriteXML(XMLWriter, "LessOrEqual", "ComparisonType", XMLTypeAssignment.Implicit);
						XMLWriter.WriteEndElement(); //For the tag "DataVisitaFact"
						
						XMLWriter.WriteStartElement("ActualVisitDate");
							WriteXML(XMLWriter, '00010101000000', "Value", XMLTypeAssignment.Implicit);
							WriteXML(XMLWriter, "NotEqual", "ComparisonType", XMLTypeAssignment.Implicit);
						XMLWriter.WriteEndElement(); //For the tag "DataVisitaFact"
						
					XMLWriter.WriteEndElement(); //For the "Filter" tag
				XMLWriter.WriteEndElement(); // For the tag "Document.Assignment to the Trade representative"
			EndIf;
		EndIf;
	EndIf;
	
	If UsingTasks <> Enums.UseJobsToSalesRepresentatives.UsedForManagementBySalesRepresentatives Then
		
		// Clearing orders at the user's request
		If StructureOfDataExchangeParameters.Property("DeleteOrders_") And StructureOfDataExchangeParameters.Property("DateWhenOrdersWereCleared") Then
			If StructureOfDataExchangeParameters.DeleteOrders_ Then
				XMLWriter.WriteStartElement("Document.SalesOrder");
					XMLWriter.WriteStartElement("Filter");
						XMLWriter.WriteStartElement("Date");
							WriteXML(XMLWriter, EndOfDay(StructureOfDataExchangeParameters.DateWhenOrdersWereCleared), "Value", XMLTypeAssignment.Implicit);
							WriteXML(XMLWriter, "LessOrEqual", "ComparisonType", XMLTypeAssignment.Implicit);
						XMLWriter.WriteEndElement(); //For the "Date" tag
					XMLWriter.WriteEndElement(); //For the "Filter" tag
				XMLWriter.WriteEndElement(); // For the tag "Document.Customer's order"
			EndIf;
		EndIf;
			
	EndIf;
	
	// Clearing advance reports on user demand
	If StructureOfDataExchangeParameters.Property("DeleteAdvanceReports") And StructureOfDataExchangeParameters.Property("DateWhenAdvanceReportsWereCleared") Then
		If StructureOfDataExchangeParameters.DeleteAdvanceReports Then
			XMLWriter.WriteStartElement("Document.ExpenseReport");
				XMLWriter.WriteStartElement("Filter");
					XMLWriter.WriteStartElement("Date");
						WriteXML(XMLWriter, EndOfDay(StructureOfDataExchangeParameters.DateWhenAdvanceReportsWereCleared), "Value", XMLTypeAssignment.Implicit);
						WriteXML(XMLWriter, "LessOrEqual", "ComparisonType", XMLTypeAssignment.Implicit);
					XMLWriter.WriteEndElement(); //For the "Date" tag
				XMLWriter.WriteEndElement(); //For the "Filter" tag
			XMLWriter.WriteEndElement(); // For the tag "Document.Advance report"
		EndIf;
	EndIf;
	
	XMLWriter.WriteEndElement(); // For the ClearData tag
	
EndProcedure

// Writes a special section of stored data to the exchange packet.
//
// Parameters:
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication - the exchange plan node for which you want to create a data cleanup section.
//  XMLWriter - XMLWriter - the XML record object that is used to record the exchange package.
//  StructureOfDataExchangeParameters - Structure - a structure containing data exchange parameters.
//
Procedure WriteSectionOfStoredData(ExchangeNode, XMLWriter, StructureOfDataExchangeParameters)
	
	SpecifyUseOfContactInformation = True;
	CurUseOfContactInformation = Undefined;
	
	UseContactDetails = Common.ObjectAttributeValue(ExchangeNode, "UseContactDetails");
	
	If StructureOfDataExchangeParameters.Property("CurUseOfContactInformation",CurUseOfContactInformation) Then
		If CurUseOfContactInformation = UseContactDetails Then
			SpecifyUseOfContactInformation = False;
		EndIf;
	Else
		SpecifyUseOfContactInformation = False;
	EndIf;

	XMLWriter.WriteStartElement("PersistentDataList");
	
	If SpecifyUseOfContactInformation Then
		WriteXML(XMLWriter, UseContactDetails, "UseContactDetails", XMLTypeAssignment.Explicit);
	EndIf;
	
	WriteXML(XMLWriter, Catalogs.PackagingGroups.SpecialForItem, "IndividualSetOfPackagesForProductRange", XMLTypeAssignment.Explicit);
		
	XMLWriter.WriteEndElement(); // PersistentDataList
		
EndProcedure

// Writes the details of the specified directory element to the exchange package.
//
// Parameters:
//  Object - CatalogObject - the object to be recorded.
//  IsFolder - Boolean - a flag that determines whether an object is a group.
//  CompositionStructure - Structure - a structure that describes the set of object fields used.
//  XMLWriter - XMLWriter - the XML record object that performs the recording.
//
Procedure AddCatalogDetailsToExchangePackage(Object, IsFolder, CompositionStructure, XMLWriter)

	AttributesStructure1 = CompositionStructure.Attributes;

	For Each Attribute In AttributesStructure1 Do

		PropsDescriptionStructure = Attribute.Value;

		If PropertyMustBeSpecified(IsFolder, PropsDescriptionStructure) Then
			WriteXML(XMLWriter, Object[Attribute.Key], Attribute.Key, PropsDescriptionStructure.TypeIndication);
		EndIf;

	EndDo;

EndProcedure

// Writes the table parts of the specified directory element to the exchange package.
//
// Parameters:
//  Object - CatalogObject - the object to be recorded.
//  IsFolder - Boolean - a flag that determines whether an object is a group.
//  CompositionStructure - Structure - a structure that describes the set of object fields used.
//  XMLWriter - XMLWriter - the XML record object that performs the recording.
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication - the data exchange node for which the exchange packet is generated.
//
Procedure WriteTablePartsOfCatalogToExchangePackage(Object, IsFolder, CompositionStructure, XMLWriter, ExchangeNode)

	StructureOfTableParts = CompositionStructure.TabularSections;

	For Each TabularSection In StructureOfTableParts Do

		StructureOfTablePartDescription = TabularSection.Value;		
					
		If PropertyMustBeSpecified(IsFolder, StructureOfTablePartDescription) Then
			
			// Let's write down each tabular part of the object in turn.
			XMLWriter.WriteStartElement(TabularSection.Key);
			
			If ItIsRequiredToUnloadDataOfTablePart(TypeOf(Object), TabularSection.Key, ExchangeNode) Then
				
				For Each LineOfATabularSection In Object[TabularSection.Key] Do
					
					// Let's write down the rows of the table part.
					XMLWriter.WriteStartElement("Row");
					
					AttributesStructure1 = StructureOfTablePartDescription.AttributesStructure1;
					
					For Each ElementOfPropsStructure In AttributesStructure1 Do
						
						AttributeName = ElementOfPropsStructure.Key;
						PropsDescriptionStructure = ElementOfPropsStructure.Value;
						
						// For each row of the tabular part, we will write down the details used.
						WriteXML(XMLWriter, LineOfATabularSection[AttributeName], AttributeName, PropsDescriptionStructure.TypeIndication);
						
					EndDo;
					
					XMLWriter.WriteEndElement(); // Row
					
				EndDo;
				
			EndIf;
			
			XMLWriter.WriteEndElement(); // name of the table part
			
		EndIf;

	EndDo;

EndProcedure

// Writes the object data to be recorded (used and standard details) to the exchange packet.
//
// Parameters:
//  Object - CatalogObject - the object to be recorded.
//  ObjectName - Structure - the name of the object to write.
//  CompositionStructure - Structure - a structure that describes the set of object fields used.
//  XMLWriter - XMLWriter - the XML record object that performs the recording.
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication - the exchange plan node for which the exchange package is generated.
//
Procedure WriteCatalogItemToExchangePackage(Object, ObjectName, CompositionStructure, XMLWriter, ExchangeNode)

	XMLWriter.WriteStartElement("CatalogObject." + ObjectName);
	
	IsFolder = Object.IsFolder;

	// Let's write down the details of the directory.
	AddCatalogDetailsToExchangePackage(Object, IsFolder, CompositionStructure, XMLWriter);

	// Let's write down the tabular parts of the directory.
	WriteTablePartsOfCatalogToExchangePackage(Object, IsFolder, CompositionStructure, XMLWriter, ExchangeNode);

	XMLWriter.WriteEndElement(); // CatalogObject
	
EndProcedure

// Writes the details of the specified document to the exchange package.
//
// Parameters:
//  Object - DocumentObject - the object to be recorded.
//  CompositionStructure - Structure - a structure that describes the set of object fields used.
//  XMLWriter - XMLWriter - the XML record object that performs the recording.
//
Procedure WriteDetailsOfDocumentInExchangePackage(Object, CompositionStructure, XMLWriter)

	AttributesStructure1 = CompositionStructure.Attributes;

	For Each Attribute In AttributesStructure1 Do

		PropsDescriptionStructure = Attribute.Value;
		WriteXML(XMLWriter, Object[Attribute.Key], Attribute.Key, PropsDescriptionStructure.TypeIndication);

	EndDo;

EndProcedure

// Writes tabular parts of the specified document to the exchange package.
//
// Parameters:
//  Object - DocumentObject - the object to be recorded.
//  CompositionStructure - Structure - a structure that describes the set of object fields used.
//  XMLWriter - XMLWriter - the XML record object that performs the recording.
//
Procedure WriteTabularPartsOfDocumentToExchangePackage(Object, CompositionStructure, XMLWriter)

	StructureOfTableParts = CompositionStructure.TabularSections;
	
	For Each TabularSection In StructureOfTableParts Do
		
		StructureOfTablePartDescription = TabularSection.Value;
		
		// Let's write down each tabular part of the object in turn.
		XMLWriter.WriteStartElement(TabularSection.Key);
		
		For Each LineOfATabularSection In Object[TabularSection.Key] Do
			
			// Let's write down the rows of the table part.
			XMLWriter.WriteStartElement("Row");
			
			AttributesStructure1 = StructureOfTablePartDescription.AttributesStructure1;
			
			For Each ElementOfPropsStructure In AttributesStructure1 Do
				
				AttributeName = ElementOfPropsStructure.Key;
				PropsDescriptionStructure = ElementOfPropsStructure.Value;

				// For each row of the tabular part, we will write down the details used.
				WriteXML(XMLWriter, LineOfATabularSection[AttributeName], AttributeName, PropsDescriptionStructure.TypeIndication);
				
			EndDo;
			
			XMLWriter.WriteEndElement(); // Row
			
		EndDo;
		
		XMLWriter.WriteEndElement(); // name of the table part
		
	EndDo;

EndProcedure

// Writes the object data to be recorded (used and standard details) to the exchange packet.
//
// Parameters:
//  Object - DocumentObject - the object to be recorded.
//  ObjectName - String - the name of the object to write.
//  CompositionStructure - Structure - a structure that describes the set of object fields used.
//  XMLWriter - XMLWriter - the XML record object that performs the recording.
//
Procedure WriteDocumentToExchangePackage(Object, ObjectName, CompositionStructure, XMLWriter)

	XMLWriter.WriteStartElement("DocumentObject." + ObjectName);

	// We will write down the details of the document.
	WriteDetailsOfDocumentInExchangePackage(Object, CompositionStructure, XMLWriter);

	// Let's write down the tabular parts of the directory.
	WriteTabularPartsOfDocumentToExchangePackage(Object, CompositionStructure, XMLWriter);

	XMLWriter.WriteEndElement(); // DocumentObject	

EndProcedure	

// Writes data for a specific object to the exchange packet.
//
// Parameters:
//  Object - CatalogObject, DocumentObject - the object to be recorded.
//  ClassName - String - name of the class that the object belongs to (reference Books, Documents, etc.).
//  ObjectName - String - the name of the metadata object to record the data for.
//  CompositionStructure - Structure - a structure that describes the set of object fields used.
//  XMLWriter - XMLWriter - the XML record object that performs the recording.
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication - the exchange plan node for which the exchange package is generated.
//
Procedure WriteDataToExchangePacket(Object, ClassName, ObjectName, CompositionStructure, XMLWriter, ExchangeNode)

	If TypeOf(Object) = Type("ObjectDeletion") Then
		WriteXML(XMLWriter, Object);
		Return;
	EndIf;

	If ClassName = "Constants" Or ClassName = "InformationRegisters" Then

		WriteXML(XMLWriter, Object);

	ElsIf ClassName = "Catalogs" Then

		WriteCatalogItemToExchangePackage(Object, ObjectName, CompositionStructure, XMLWriter, ExchangeNode);

	ElsIf ClassName = "Documents" Then

		WriteDocumentToExchangePackage(Object, ObjectName, CompositionStructure, XMLWriter);

	EndIf;

EndProcedure

// Defines and returns whether the metadata object property must be specified.
//
// Parameters:
//  ThisIsCatalogGroup - Boolean - a flag that determines whether an object is a group.
//  PropertyDescriptionStructure - Structure - a structure containing a description of the property (a variant of using a prop or PM).
//
// Returns:
//  Boolean - a sign of necessity. True - the property must be specified, False - the indication is not required.
//
Function PropertyMustBeSpecified(ThisIsCatalogGroup, PropertyDescriptionStructure)

	If ThisIsCatalogGroup Then
		Return PropertyDescriptionStructure.UsedForGroup;
	Else
		Return PropertyDescriptionStructure.UsedForElement;
	EndIf;

EndFunction

// Analyzes whether to include object data in the exchange package.
//
// Parameters:
//  ObjectDescriptionStructure_ - Structure - structure containing the object description.
//  StructureOfDataExchangeParameters - Structure - a structure containing data exchange parameters.
//
// Returns:
//  Boolean - the need to include data. True - the data should be included in the exchange package, False - it is not necessary.
//
Function IncludeDataInExchangePackage(ObjectDescriptionStructure_, StructureOfDataExchangeParameters)
	
	If ObjectDescriptionStructure_.ClassName = "Catalogs" Then
		
		If ObjectDescriptionStructure_.ObjectName = "ProductsAttachedFiles" Then
			
			GetImagesOfProducts = False;
			If StructureOfDataExchangeParameters.Property("GetImagesOfProducts") Then
				GetImagesOfProducts = StructureOfDataExchangeParameters.GetImagesOfProducts;
			EndIf;
			
			Return GetImagesOfProducts;
			
		EndIf;
		
	ElsIf ObjectDescriptionStructure_.ClassName = "InformationRegisters" Then
		
		If ObjectDescriptionStructure_.ObjectName = "GoodsAvailabilityForExternalUsers" Then
			
			GetInformationAboutAvailableProducts = False;
			If StructureOfDataExchangeParameters.Property("GetInformationAboutAvailableProducts") Then
				GetInformationAboutAvailableProducts = StructureOfDataExchangeParameters.GetInformationAboutAvailableProducts;
			EndIf;
			
			Return GetInformationAboutAvailableProducts;
			
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

// Analyzes whether data from the specified table part needs to be uploaded.
//
// Parameters:
//  ObjectType - Type - the type of object that the table part belongs to.
//  TabularSectionName - String - name of the table part to check if it needs to be unloaded.
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication - the exchange plan node for which data is being uploaded.
//
// Returns:
//  Boolean - a sign of the need to unload. True - unloading is required, False - not required.
//
Function ItIsRequiredToUnloadDataOfTablePart(ObjectType, TabularSectionName, ExchangeNode)
	
	If ObjectType = Type("CatalogObject.Partners") And TabularSectionName = "ContactInformation" Then
		UseContactDetails = Common.ObjectAttributeValue(ExchangeNode, "UseContactDetails");
		Return Not (UseContactDetails = Enums.ContactDetailsUsageByMobileApplication.NotUsed);
	EndIf;
	
	Return True;
	
EndFunction

// Processes the specified object before writing to the batch.
//
// Parameters:
//  Object - CatalogObject, DocumentObject - the object to be processed.
//  ClassName - String - name of the class of the object being processed.
//  ObjectName - String - name of the object to be processed.
//  StructureOfDataExchangeParameters - Structure - a structure containing data exchange parameters.
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication - the exchange site.
//
Procedure ProcessObjectBeforeWritingToExchangePacket(Object, ClassName, ObjectName, StructureOfDataExchangeParameters, ExchangeNode)
	
	If TypeOf(Object) = Type("ObjectDeletion") Then
		Return;
	EndIf;
	
	If ClassName = "Catalogs" Then
		If ObjectName = "ProductsAttachedFiles" Then
			If ExchangeNode.Metadata().Name = "SalesRepresentativeMobileApplication" Then
				ProcessAttachedFileBeforeWritingToPackage(Object);
			EndIf;
		EndIf;
	ElsIf ClassName = "Documents" Then
		If ObjectName = "JobForSalesRepresentative" Then
			ProcessTaskForSalesRepresentativeBeforeWritingToPackage(Object, StructureOfDataExchangeParameters);
		EndIf;
	EndIf;
	
EndProcedure

// Processes the task for the sales representative.
//
// Parameters:
//  Object - DocumentObject - the object to be processed.
//  StructureOfDataExchangeParameters - Structure - a structure containing data exchange parameters.
//
Procedure ProcessTaskForSalesRepresentativeBeforeWritingToPackage(Object, StructureOfDataExchangeParameters)
	
	CompletingTasksBasedOnSalesHistoryDataIsRequired = False;
	FillingInDataOnSettlementsWithCustomersIsRequired = False;
	
	UsingTasks = Constants.UseJobsToSalesRepresentatives.Get();
	DetailTasks = Constants.ItemizeJobsForSalesRepresentatives.Get();
	
	If UsingTasks = Enums.UseJobsToSalesRepresentatives.UsedBySalesRepresentativesForPlanning Then
		If StructureOfDataExchangeParameters.Property("FillInTasksBasedOnSalesHistoryData") Then
			CompletingTasksBasedOnSalesHistoryDataIsRequired = StructureOfDataExchangeParameters.FillInTasksBasedOnSalesHistoryData;
		EndIf;
	EndIf;
	
	If StructureOfDataExchangeParameters.Property("ReceiveInformationAboutSettlementsWithClients") Then
		FillingInDataOnSettlementsWithCustomersIsRequired = StructureOfDataExchangeParameters.ReceiveInformationAboutSettlementsWithClients;
	EndIf;
	
	If CompletingTasksBasedOnSalesHistoryDataIsRequired Or FillingInDataOnSettlementsWithCustomersIsRequired Then
		Try
			If CompletingTasksBasedOnSalesHistoryDataIsRequired Then
				FillInTaskWithSalesHistoryData(Object, StructureOfDataExchangeParameters);
			EndIf;
			
			If FillingInDataOnSettlementsWithCustomersIsRequired Then
				Object.FillInDataOnAccountsReceivable();
				Object.AddAutomaticTasks();
			EndIf;
			
			Object.AdditionalProperties.Insert("NotRegisterChanges", True);
			Object.Write();
		Except
			DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
		
			MessageText = ErrorInfo().Description;
			WriteLogEvent(NStr("vi = 'Lỗi ghi công việc cho đại diện bán hàng';
								|ru = 'Ошибка при записи задания торговому представителю';
								|en = 'An error occurred when saving a sales representative task'; fa = 'An error occurred when saving a sales representative task';
								|it = 'Errore durante la scrittura di un lavoro a un rappresentante di vendita';
								|pl = 'Błąd podczas zapisu zadania przedstawiciela handlowego';
								|tr = 'Satış temsilcisine görev yazılırken hata oluştu'", DefaultLanguageCode),
								EventLogLevel.Error,
								,
								,
								MessageText);
		EndTry;
		
	EndIf;
	
EndProcedure

Procedure ProcessAttachedFileBeforeWritingToPackage(Object)
	
	Object.FileStorage = New ValueStorage(FilesOperations.FileBinaryData(Object.Ref));
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfWorkingWithReceivedExchangePackets

// Reads object data from the exchange packet and reflects this data in the is.
//
// Parameters:
//  XMLReader - XMLReader - the object that is used to read the package.
//  ObjectName - String - name of the data object to be read.
//  ObjectComposition - Structure - a structure that describes the composition of a data object.
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication - the exchange plan node for which the exchange packet was received.
//
// Returns:
//  CatalogObject - an object updated or created according to the data of the exchange package.
//
Function ReadAndEditCatalogItem(XMLReader, ObjectName, ObjectComposition, ExchangeNode)

	ObjectTree = ObjectDataFROMXML(XMLReader, "Catalogs", ObjectName, ObjectComposition);
	Id_String = GetLinkIDFromObjectTree(ObjectTree);

	ObjectReference = GetRef(Id_String, "Catalogs", ObjectName);
	DataObject = ObjectReference.GetObject();

	If DataObject = Undefined Then
		// Let's create a new object.
		IsFolder = GetPropsValueFromObjectTree("IsFolder", ObjectTree);
		If IsFolder<> Undefined And IsFolder Then
			DataObject = Catalogs[ObjectName].CreateFolder();
		Else
			DataObject = Catalogs[ObjectName].CreateItem();
		EndIf;

		DataObject.SetNewObjectRef(ObjectReference);

	EndIf;

	FillObjectInTree(DataObject, ObjectTree, ObjectComposition, ExchangeNode);

	Return DataObject;

EndFunction

// Reads object data from the exchange packet and reflects this data in the is.
//
// Parameters:
//  XMLReader - XMLReader - the object that is used to read the package.
//  ObjectName - String - name of the data object to be read.
//  ObjectComposition - Structure - a structure that describes the composition of a data object.
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication- the site plan of exchange to which the received data.
//
// Returns:
//  DocumentObject - an object updated or created according to the data of the exchange package.
//
Function ReadAndModifyDocument(XMLReader, ObjectName, ObjectComposition, ExchangeNode)

	ObjectTree = ObjectDataFROMXML(XMLReader, "Documents", ObjectName, ObjectComposition);

	Id_String = GetLinkIDFromObjectTree(ObjectTree);

	ObjectReference = GetRef(Id_String, "Documents", ObjectName);
	DataObject = ObjectReference.GetObject();

	If DataObject = Undefined Then
		// Let's create a new object.
		DataObject = Documents[ObjectName].CreateDocument();
		DataObject.SetNewObjectRef(ObjectReference);
	EndIf;

	FillObjectInTree(DataObject, ObjectTree, ObjectComposition, ExchangeNode);

	Return DataObject;

EndFunction

// Fills in the properties of the passed data object
// based on data read from XML to the object tree.
//
// Parameters:
//  DataObject - CatalogObject, DocumentObject - the element of the dictionary, go the document.
//  ObjectTree - ValueTree - a value tree containing the object data read from the exchange packet.
//  ObjectComposition - Structure - structure that describes the object's composition.
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication - the site plan of exchange to which the received data.
//
Procedure FillObjectInTree(DataObject, ObjectTree, ObjectComposition, ExchangeNode)

	// Fill in the details of the object.
	AttributesRow = ObjectTree.Rows.Find("Attributes", "Name");
	
	AttributesStructure1 = ObjectComposition.Attributes;
	StructureOfTableParts = ObjectComposition.TabularSections;

	For Each PropsString In AttributesRow.Rows Do
		
		// Checking the presence of the props in the current configuration.
		If Not AttributesStructure1.Property(PropsString.Name) Then
			Continue;
		EndIf;

		If (PropsString.Name <> "Ref") And (PropsString.Name <> "Ref")
			And (PropsString.Name <> "IsFolder") And (PropsString.Name <> "IsFolder") Then 
			// The link is put down separately.
			AttributeValue = GetValueFromXMLString(PropsString.Type, PropsString.Value);
			DataObject[PropsString.Name] = AttributeValue;
		EndIf;

	EndDo;

	// Fill in the tabular parts of the object.
	StringOfTableParts = ObjectTree.Rows.Find("TabularSections", "Name");

	If StringOfTableParts <> Undefined Then
		// For each row of the tree corresponding to the table part, you need to fill in the rows of this PM.
		For Each TSRow In StringOfTableParts.Rows Do

			If Not StructureOfTableParts.Property(TSRow.Name) Then
				Continue;
			EndIf;
		
			If Not LoadingDataOfTablePartIsRequired(TypeOf(DataObject),TSRow.Name, ExchangeNode) Then
				Continue;
			EndIf;
			
			TabularSection = DataObject[TSRow.Name];
			TabularSection.Clear();

			// We look through each row of the tabular part.
			For Each LineOfATabularSection In TSRow.Rows Do

				NewLineOfTablePart = TabularSection.Add();

				// We fill in every detail of the row of the table part.
				For Each TSPropsString In LineOfATabularSection.Rows Do

					AttributeValue = GetValueFromXMLString(TSPropsString.Type, TSPropsString.Value);
					NewLineOfTablePart[TSPropsString.Name] = AttributeValue;
					
				EndDo;

			EndDo;

		EndDo;

	EndIf;

EndProcedure

// Generates and returns an object tree based on data read from XML.
//
// Parameters:
//  XMLReader - XMLReader - the object that is used for reading.
//  ClassName - String - name of the class that the object belongs to (reference Books, Documents, etc.).
//  ObjectName - String - name of the object that is being read and for which you want to form a tree.
//  ObjectComposition - Structure - structure that describes the object's composition.
//
// Returns:
//  ValueTree - a tree containing the read object data.
//
Function ObjectDataFROMXML(XMLReader, ClassName, ObjectName, ObjectComposition)

	ObjectTree = New ValueTree();

	ObjectTree.Columns.Add("Name");
	ObjectTree.Columns.Add("Type");
	ObjectTree.Columns.Add("Value");

	Attributes = ObjectTree.Rows.Add();
	Attributes.Name = "Attributes";

	TabularSections = ObjectTree.Rows.Add();
	TabularSections.Name = "TabularSections";
	
	CurrentRow = Undefined; // ValueTreeRow
	TabularSection = Undefined;  // ValueTreeRow 
	LineOfATabularSection = Undefined; // ValueTreeRow

	NestingLevel = 1;

	While XMLReader.Read() Do
		
		If XMLReader.NodeType = XMLNodeType.StartElement Then
			
			NestingLevel = NestingLevel + 1;
			
			// Reading the element.
			If NestingLevel = 2 Then

				// This is either a prop or a tabular part - you need to determine which one.
				If PropertyIsProp(ClassName, ObjectName, XMLReader.Name, ObjectComposition) Then
					CurrentRow = Attributes.Rows.Add();
				ElsIf PropertyIsTabularPart(ClassName, ObjectName, XMLReader.Name, ObjectComposition) Then	
					CurrentRow = TabularSections.Rows.Add();
					TabularSection = CurrentRow;
				EndIf;

			ElsIf NestingLevel = 3 Then

				// This is a row of the table part.
				If TabularSection <> Undefined Then
					CurrentRow = TabularSection.Rows.Add();
					LineOfATabularSection = CurrentRow;
				EndIf;

			ElsIf NestingLevel = 4 Then
		
				// These are the details of the row of the table part.
				If LineOfATabularSection <> Undefined Then
					CurrentRow = LineOfATabularSection.Rows.Add();
				EndIf;

			EndIf;
			
			If CurrentRow <> Undefined Then
				
				CurrentRow.Name = XMLReader.Name;
				
				// Reading the attributes of the element.
				While XMLReader.ReadAttribute() Do

					Type = Undefined;

					// If the type is specified, we will read it.
					If XMLReader.Name = "xsi:type" Then 
						Type = GetTypeByString(XMLReader.Value);
					ElsIf XMLReader.Name = "xsi:nil" Then
						Type = Undefined;
					EndIf;
					
					CurrentRow.Type = Type;
					
				EndDo;
				
			EndIf;
			
		ElsIf XMLReader.NodeType = XMLNodeType.EndElement Then
			
			If CurrentRow <> Undefined Then

				If CurrentRow.Type = Undefined Then
					
					IsAttribute = False;

					TabularSectionName = "";
					If NestingLevel = 4 Then // If this is the props of the table part

						If TabularSection <> Undefined Then
							IsAttribute = True;
							TabularSectionName = TabularSection.Name;
						EndIf;

					ElsIf NestingLevel = 2 Then
						IsAttribute = PropertyIsProp(ClassName, ObjectName, XMLReader.Name, ObjectComposition);
					EndIf;

					If IsAttribute Then
						CurrentRow.Type = GetTypeFromMetadata(CurrentRow.Name, TabularSectionName, ObjectComposition);
					EndIf;

				EndIf;

				If CurrentRow.Value = Undefined Then
					CurrentRow.Value = "";
				EndIf;

			EndIf;

			NestingLevel = NestingLevel - 1;

			If NestingLevel <= 0 Then
				XMLReader.Read();
				Return ObjectTree;
			EndIf;
			
		Else

			If CurrentRow <> Undefined Then
				// Take the value.
				CurrentRow.Value = XMLReader.Value;

				TabularSectionName = "";
				If NestingLevel = 4 Then // If this is the props of the table part
					If TabularSection <> Undefined Then
						TabularSectionName = TabularSection.Name;
					EndIf;
				EndIf;

				If CurrentRow.Type = Undefined Then
					CurrentRow.Type = GetTypeFromMetadata(CurrentRow.Name, TabularSectionName, ObjectComposition);
				EndIf;

			EndIf;
			
		EndIf;
		
	EndDo;

	Return ObjectTree;

EndFunction

// Gets and returns the value of the specified attribute contained in 
// the object tree.
//
// Parameters:
//  AttributeName - String - name of the prop whose value you want to get.
//  ObjectTree - ValueTree - the value tree that contains the data object.
//
// Returns:
//  Arbitrary - the value of the props.
//
Function GetPropsValueFromObjectTree(AttributeName, ObjectTree)

	AttributesRow = ObjectTree.Rows.Find("Attributes", "Name");
	PropsString = AttributesRow.Rows.Find(AttributeName, "Name");

	If PropsString = Undefined Then
		Return Undefined;
	EndIf;

	StringValue = PropsString.Value;
	Type = PropsString.Type;

	Return GetValueFromXMLString(Type, StringValue);

EndFunction

// Determines whether the specified property is a property of the object or not.
//
// Parameters:
//  ClassName - String - name of the class that the object belongs to (reference Books, Documents, etc.).
//  ObjectName - String - name of the object whose property you want to analyze.
//  ObjectComposition - Structure - a structure that describes the composition of the metadata object.
//
// Returns:
//  Boolean - the result of checking the property. True - property is a prop, False - is not.
//
Function PropertyIsProp(ClassName, ObjectName, PropertyName, ObjectComposition)

	// We will immediately check the standard banking details.
	If ClassName = "Catalogs" Then
		If PropertyName = "Ref"
			Or PropertyName = "IsFolder"
			Or PropertyName = "DeletionMark"
			Or PropertyName = "Parent"
			Or PropertyName = "Code"
			Or PropertyName = "Description"
			Or PropertyName = "Owner" Then

			Return True;

		EndIf;

	ElsIf ClassName = "Documents" Then

		If PropertyName = "Ref"
			Or PropertyName = "DeletionMark"
			Or PropertyName = "Date"
			Or PropertyName = "Number"
			Or PropertyName = "Posted" Then

			Return True;

		EndIf;

	EndIf;

	AttributesStructure1 = ObjectComposition["Attributes"];

	Return AttributesStructure1.Property(PropertyName);

EndFunction

// Determines whether the specified property is a table part of the object or not.
//
// Parameters:
//  ClassName - String - name of the class that the object belongs to (reference Books, Documents, etc.).
//  ObjectName - String - name of the object whose property you want to analyze.
//  ObjectComposition - Structure - a structure that describes the composition of the metadata object.
//
// Returns:
//  Boolean - the result of the check. True - a property is a tabular part, False - it is not.
//
Function PropertyIsTabularPart(ClassName, ObjectName, PropertyName, ObjectComposition)

	// We will immediately check the standard banking details.
	If ClassName = "Catalogs" Or ClassName = "Documents" Then
		StructureOfTableParts = ObjectComposition["TabularSections"];
		Return StructureOfTableParts.Property(PropertyName);
	Else
		Return False;
	EndIf;

EndFunction

// Gets and returns a reference to an object by a unique string identifier.
//
// Parameters:
//  Id_String - String - string of the unique link ID.
//  ClassName - String - name of the class to which the object belongs (Directories, Documents, etc.).
//  ObjectName - String - name of the metadata object to get a reference for.
//
// Returns:
//  CatalogRef, DocumentRef - object reference.
//
Function GetRef(Id_String, ClassName, ObjectName)

	If Id_String = Undefined Then
		Return Undefined;
	EndIf;		
	
	If ClassName = "Catalogs" Then
		
		ObjectReference = XMLValue(Type("CatalogRef." + ObjectName), Id_String);
				
	ElsIf ClassName = "Documents" Then
		
		ObjectReference = XMLValue(Type("DocumentRef." + ObjectName), Id_String);
			
	EndIf;
	
	Return ObjectReference;

EndFunction

// Gets and returns the string reference ID from the object tree.
//
// Parameters:
//  ObjectTree - ValueTree - the value tree that contains the data object.
//
// Returns:
//  String - The string is the link ID.
//
Function GetLinkIDFromObjectTree(ObjectTree)

	AttributesRow = ObjectTree.Rows.Find("Attributes", "Name");
	RefRow = AttributesRow.Rows.Find("Ref", "Name");

	Return RefRow.Value;

EndFunction

// Gets and returns the value read from XML
// as a value of the required type.
//
// Parameters:
//  Type - Type - Type for the value.
//  ValueRow - String - the value of the string obtained from XML.
//
// Returns:
//  Arbitrary - The value obtained from the XML string.
//
Function GetValueFromXMLString(Type, ValueRow)

	If Type = Undefined Then
		Return Undefined;
	Else
		Return XMLValue(Type, ValueRow);
	EndIf;

EndFunction

// Gets and returns the type for the specified metadata object props.
//
// Parameters:
//  AttributeName - String - name of the prop that you want to get the type of.
//  TabularSectionName - String - name of the table part that the prop belongs to.
//  ObjectComposition - Structure - structure containing the object description.
//
// Returns:
//  Type - The type of the prop.
//
Function GetTypeFromMetadata(AttributeName, TabularSectionName, ObjectComposition)

	If IsBlankString(TabularSectionName) Then
		// This is the object's props.
		AttributesStructure1 = ObjectComposition["Attributes"];
		PropsDescriptionStructure = AttributesStructure1[AttributeName];
		Type = PropsDescriptionStructure["Type"];
	Else
		 // This is the props of the tabular part.
		StructureOfTableParts = ObjectComposition["TabularSections"];
		StructureOfTablePartDescription = StructureOfTableParts[TabularSectionName];
		StructureOfDetailsOfTablePart = StructureOfTablePartDescription["AttributesStructure1"];
		PropsDescriptionStructure = StructureOfDetailsOfTablePart[AttributeName];
		Type = PropsDescriptionStructure.Type;
	EndIf;

	Return Type;

EndFunction

// Gets and returns a type based on a type string obtained from XML.
//
// Parameters:
//  XMLTypeRow - String - string description of the type.
//
// Returns:
//  Type - object type.
//
Function GetTypeByString(XMLTypeRow)

	ClassName = "";
	ObjectName = "";
	DefineClassAndTypeNameByDataType(XMLTypeRow, ClassName, ObjectName);

	If IsBlankString(ClassName) Then

		Return Undefined;
	
	ElsIf ClassName = "CATALOGREF" Then

		Return Type("CatalogRef." + ObjectName);

	ElsIf ClassName = "DOCUMENTREF" Then

		Return Type("DocumentRef." + ObjectName);

	ElsIf ClassName = "ENUMREF" Then

		Return Type("EnumRef." + ObjectName);

	ElsIf ClassName = "XSD:STRING" Then

		Return Type("String");

	ElsIf ClassName = "XSD:DECIMAL" Then

		Return Type("Number");
		
	ElsIf ClassName = "XSD:DATETIME" Then

		Return Type("Date");
		
	ElsIf ClassName = "XSD:BOOLEAN" Then

		Return Type("Boolean");
		
	ElsIf ClassName = "XSI:NIL" Then

		Return Undefined;
		
	ElsIf ClassName = "XSD:BASE64BINARY" Then

		Return Type("BinaryData");
		
	ElsIf ClassName = "V8:VALUESTORAGE" Then	
		
		Return Type("ValueStorage");
						
	Else
		#If ExternalConnection Then
		MessageText = NStr("vi = 'Không xác định được kiểu dữ liệu trong gói trao đổi';
							|ru = 'Неизвестный тип данных в пакете обмена';
							|en = 'Unknown data type in the exchange package'; fa = 'Unknown data type in the exchange package';
							|it = 'Tipo di dati sconosciuto nel pacchetto di scambio';
							|pl = 'Nieznany typ danych w pakiecie wymiany';
							|tr = 'Değişim paketinde bilinmeyen veri türü'");
		Raise(MessageText);
		#EndIf
	EndIf;

EndFunction

// Defines the name of the corresponding class and object based on the data type obtained from XML.
//
// Parameters:
//  DataType - String - the string data type.
//  ClassName - String - name of the object class (reference Books, Documents, etc.).
//  ObjectName - String - name of the specific metadata object.
//
Procedure DefineClassAndTypeNameByDataType(Val DataType, ClassName, ObjectName)

	PointPosition = StrFind(DataType, ".");
	DataTypeName = "";
	If PointPosition > 0 Then
			
		ClassName = Upper(Mid(DataType, 1, PointPosition - 1)); 
		ObjectName = Mid(DataType, PointPosition + 1);
			
	Else
		// the type could not be determined.
		ClassName = Upper(DataType);
			
	EndIf;

EndProcedure

// Analyzes whether data from the specified table part needs to be loaded.
//
// Parameters:
//  ObjectType - Type - the type of object that the table part belongs to.
//  TabularSectionName - String - name of the table part to check if it needs to be unloaded.
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication - the exchange plan node for which data is being uploaded.
//
// Returns:
//  Boolean - the result of the check. True - unloading is required, False - not required.
//
Function LoadingDataOfTablePartIsRequired(ObjectType, TabularSectionName, ExchangeNode)
	
	If ObjectType = Type("CatalogObject.Partners") And TabularSectionName = "ContactInformation" Then
		UseContactDetails = Common.ObjectAttributeValue(ExchangeNode, "UseContactDetails");
		Return (UseContactDetails = Enums.ContactDetailsUsageByMobileApplication.UsedForReadingAndWriting);
	ElsIf ObjectType = Type("DocumentObject.JobForSalesRepresentative") 
		And (TabularSectionName = "ARAPByOrders") Or (TabularSectionName = "ReceivablesDrillDownReport") Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Determines whether the specified object needs to register changes in the sending node.
//
// Parameters:
//  ClassName - String - name of the class to which the object belongs (Directories, Documents, etc.).
//  ObjectName - String - the name of the metadata object for which you want check.
//
// Returns:
//  Boolean - A sign of the need to register changes.
//
Function YouNeedToRegisterChangesForSenderNode(ClassName, ObjectName, ReadObject_)
	
	If ClassName = "DOCUMENTOBJECT" Then
		If ObjectName = "JobForSalesRepresentative" Then
			If ReadObject_.Status = Enums.SalesRepresentativeTaskStatuses.NotPrepared2 Then
				Return True;
			EndIf;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsForFillingAndProcessingObjectsReceivedFromExchangePackage

// Fills in the object received during the exchange - 
// sets the values of the object's empty details, if necessary.
//
// Parameters:
//  Object - CatalogObject, DocumentObject - the object being recorded.
//  ClassName - String - name of the class to which the object belongs (reference Books, Documents).
//  ObjectName - String - the name of the object being written, as defined in the metadata.
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication - the exchange node from which the data is received.
//
Procedure ProcessFillingInNewObject(Object, ClassName, ObjectName, ExchangeNode)

	// It makes sense to fill in only for new objects.
	If Not Object.IsNew() Then
		Return;
	EndIf;

	If ClassName = "Catalogs" Then
		ProcessCatalogFilling(Object, ObjectName, ExchangeNode);
	ElsIf ClassName = "Documents" Then
		ProcessDocumentFilling(Object, ObjectName, ExchangeNode);
	EndIf;

EndProcedure

// Fills in the directory element (group) received during the exchange -
// sets the values of the object's empty details, if necessary.
//
// Parameters:
//  Object - CatalogObject - the object being recorded.
//  ObjectName - String - the name of the object being written, as defined in the metadata.
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication - the exchange node from which the data is received.
//
Procedure ProcessCatalogFilling(Object, ObjectName, ExchangeNode)

	If ObjectName = "Partners" Then
		ProcessPartnerFilling(Object, ExchangeNode);
	EndIf;
	
EndProcedure

// Fills in the document received during the exchange -
// sets the values of the object's blank details, if necessary.
//
// Parameters:
//  Object - CatalogObject, DocumentObject - the object being recorded.
//  ObjectName - String - the name of the object being written, as defined in the metadata.
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication - the exchange node from which the data is received.
//
Procedure ProcessDocumentFilling(Object, ObjectName, ExchangeNode)

	If ObjectName = "SalesOrder" Then
		ProcessCustomerOrderFilling(Object, ExchangeNode);
	ElsIf ObjectName = "ExpenseReport" Then
		ProcessAdvanceReportFilling(Object, ExchangeNode);
	EndIf;

EndProcedure

// Fills in the partner received during the exchange.
//
// Parameters:
//  Object - CatalogObject.Partners - the reference and object partners.
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication - the exchange node from which the data is received.
//
Procedure ProcessPartnerFilling(Object, ExchangeNode)
	
	Object.Client = True;

EndProcedure

// Fills in the customer's order received during the exchange.
//
// Parameters:
//  Object - DocumentObject.SalesOrder - document-the customer's Order object.
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication - the exchange node from which the data is received.
//
Procedure ProcessCustomerOrderFilling(Object, ExchangeNode)
	
	If Not ValueIsFilled(Object.Status) Then
		Object.Status = Enums.SalesOrderStatuses.NotApproved;
	EndIf;

	Object.Priority = SettingsValueCached.GetDefaultPriority(Object.Priority);

	If Not ValueIsFilled(Object.Manager) Then
		User = Common.ObjectAttributeValue(ExchangeNode, "User");
		Object.Manager = User;
	EndIf;
	
	OrdersServer.SetKeyInRowsOfTablePart(Object, "Goods");
	Object.DocumentAmount = Object.GetSumOfOrderedRows();	

EndProcedure

// Fills in the advance report received during the exchange.
//
// Parameters:
//  Object - DocumentObject.ExpenseReport -document - object advance Report.
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication - the exchange node from which the data is received.
//
Procedure ProcessAdvanceReportFilling(Object, ExchangeNode)
	
	If Not ValueIsFilled(Object.AdvanceHolder) Then
		Individual = Common.ObjectAttributeValue(ExchangeNode, "User.Individual");
		Object.AdvanceHolder = Individual;
	EndIf;

EndProcedure

// Performs the processing steps of the recorded objects.
//
// Parameters:
//  Object - DocumentObject - The recorded object.
//
Procedure ProcessRecordedObject(Object, StructureOfExchangeSettings, ExchangeNode)
	
	If TypeOf(Object) = Type("DocumentObject.JobForSalesRepresentative") Then
		If Object.Status = Enums.SalesRepresentativeTaskStatuses.NotPrepared2 Then
			FillInTask(Object, ExchangeNode);
		Else
			If StructureOfExchangeSettings.AutomaticallyCreateOrdersForJob Then
				CreateCustomerOrderForTask(Object);
			EndIf;
		EndIf;
	EndIf;

EndProcedure

// Creates an order based on the task for the sales representative.
//
// Parameters:
//  Job - DocumentRef.JobForSalesRepresentative - link to the task for which you want to create an order.
//
Procedure CreateCustomerOrderForTask(Job)
	
	// For tasks for which orders already exist, recording new ones in automatic mode is not allowed.
	If ThereAreOrdersForTheJob(Job.Ref) Then
		Return;
	EndIf;
	
	If Job.Goods.Total("Count") = 0 Then
		Return;
	EndIf;
		
	SalesOrder = Documents.SalesOrder.CreateDocument();
	SalesOrder.Fill(Job.Ref);
	SalesOrder.Date = CurrentSessionDate();
	SalesOrder.Manager = Job.SalesRepresentative;
	
	OrdersServer.SetKeyInRowsOfTablePart(SalesOrder, "Goods");
	SalesOrder.DocumentAmount = SalesOrder.GetSumOfOrderedRows();
	
	SalesOrder.Write();
	
	// After recording the order, the system tries to carry it out.
	Try
		SalesOrder.Write(DocumentWriteMode.Posting);
	Except
		DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
		
		MessageText = ErrorInfo().Description;
		WriteLogEvent(NStr("vi = 'Lỗi ghi đơn đặt hàng';
							|ru = 'Ошибка при записи заказа клиента';
							|en = 'An error occurred when writing the sales order'; fa = 'An error occurred when writing the sales order';
							|it = 'Errore durante la scrittura dell''ordine cliente';
							|pl = 'Błąd podczas zapisu zamówienia klienta';
							|tr = 'Müşteri siparişi yazılırken hata oluştu'", DefaultLanguageCode),
								EventLogLevel.Error,
								,
								,
								MessageText);
	EndTry;	
	
EndProcedure

// Analyzes whether there are orders for the specified task.
//
// Parameters:
//  Job - DocumentRef.JobForSalesRepresentative - the task for which the availability of orders is checked.
//
// Returns:
//  Boolean - the result of the check. True - there are orders, False - no.
//
Function ThereAreOrdersForTheJob(Job)
	
	QueryText = 
	"SELECT ALLOWED
	|	SalesOrder.Ref AS Ref
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|WHERE
	|	SalesOrder.DocumentBasis = &Job
	|	AND (NOT SalesOrder.DeletionMark)"
	;
	
	Query = New Query();
	Query.Text = QueryText;
	Query.SetParameter("Job", Job);
	
	QueryResult = Query.Execute();
	Return Not QueryResult.IsEmpty();
	
EndFunction

// Performs automatic task completion.
//
// Parameters:
//  Job - DocumentObject.JobForSalesRepresentative - The document "task to the trade Representative", which must be filled in.
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication -the exchange plan node that the document that needs to be filled in was received from.
//
Procedure FillInTask(Job, ExchangeNode)

	Job.FillInDocumentAccordingToAgreement();
	User = Common.ObjectAttributeValue(ExchangeNode, "User");

	Job.Supervisor_ = User;
	Job.SalesRepresentative = User;
	
	If Constants.ItemizeJobsForSalesRepresentatives.Get() Then
		Job.Status = Enums.SalesRepresentativeTaskStatuses.ToProcessing;
	EndIf;
	
	Try
		Job.Write();
	Except
		DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
		
		MessageText = ErrorInfo().Description;
		WriteLogEvent(NStr("vi = 'Lỗi ghi công việc cho đại diện bán hàng';
							|ru = 'Ошибка при записи задания торговому представителю';
							|en = 'An error occurred when saving a sales representative task'; fa = 'An error occurred when saving a sales representative task';
							|it = 'Errore durante la scrittura di un lavoro a un rappresentante di vendita';
							|pl = 'Błąd podczas zapisu zadania przedstawiciela handlowego';
							|tr = 'Satış temsilcisine görev yazılırken hata oluştu'", DefaultLanguageCode),
								EventLogLevel.Error,
								,
								,
								MessageText);
	EndTry;

EndProcedure

// Completes the specified task based on the sales history data.
//
// Parameters:
//  Job - DocumentObject.JobForSalesRepresentative - The task that you want to complete.
//  StructureOfDataExchangeParameters - Structure - a structure containing data exchange parameters.
//
Procedure FillInTaskWithSalesHistoryData(Job, StructureOfDataExchangeParameters)
	
	FillInTasksWithDetailedCharacteristics = False;
	StartOfSalesHistoryAnalysisPeriod = '00010101000000';
	EndOfSalesHistoryAnalysisPeriod = '00010101000000';
	
	If Constants.UseItemVariants.Get() Then
		If StructureOfDataExchangeParameters.Property("FillInTasksWithDetailedCharacteristics") Then
			FillInTasksWithDetailedCharacteristics = StructureOfDataExchangeParameters["FillInTasksWithDetailedCharacteristics"];
		EndIf;
	EndIf;
	
	If StructureOfDataExchangeParameters.Property("StartOfSalesHistoryAnalysisPeriod") Then
		StartOfSalesHistoryAnalysisPeriod = StructureOfDataExchangeParameters["StartOfSalesHistoryAnalysisPeriod"];
	EndIf;
	
	If StructureOfDataExchangeParameters.Property("EndOfSalesHistoryAnalysisPeriod") Then
		EndOfSalesHistoryAnalysisPeriod = StructureOfDataExchangeParameters["EndOfSalesHistoryAnalysisPeriod"];
	EndIf;
	
	PeriodDetails = New Structure;
	PeriodDetails.Insert("Period", "day");
	PeriodDetails.Insert("BeginOfPeriod", StartOfSalesHistoryAnalysisPeriod);
	PeriodDetails.Insert("EndOfPeriod", EndOfSalesHistoryAnalysisPeriod);
		
	Job.FillInSalesHistory(PeriodDetails, FillInTasksWithDetailedCharacteristics);
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForManagingChangeLoggingAndDataSampling

// Selects and returns the data to be registered for changes based on the exchange scheme
// defined for the node.
//
// Parameters:
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication -the exchange plan node where changes are registered.
//  ObjectDescriptionStructure_ - Structure - the structure that stores the description of the metadata object.
//  StructureOfSelectionSettings - Structure - structure containing the exchange settings.
//  StructureOfExchangeSettings - Structure - structure that contains the configuration settings of exchange.
//
// Returns:
//  QueryResultSelection - Selection of data subject to registration of changes.
//
Function SelectLinksToRegisterChanges(ExchangeNode, ObjectDescriptionStructure_, StructureOfSelectionSettings, StructureOfExchangeSettings)
	
	QueryText = GetRequestTextForFetchingReferenceData(ObjectDescriptionStructure_, StructureOfExchangeSettings);
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Ref", Undefined);
	ParametersStructure.Insert("Changes", False);
	ParametersStructure.Insert("ExchangeNode", Undefined);
	ParametersStructure.Insert("MessageNo", Undefined);
	ParametersStructure.Insert("UseAdditionalSelections", False);
	
	Query = GetRequestForObject(QueryText,
									  ObjectDescriptionStructure_,
									  StructureOfSelectionSettings,
									  StructureOfExchangeSettings,
									  ParametersStructure);

	QueryResult = Query.Execute();
	
	Return QueryResult.Select();

EndFunction

// Generates and returns a table of values containing data register entries selected according to the exchange scheme conditions.
//
// Parameters:
//  Structurationist - Structure - structure containing the object description.
//  Selection structureconstruction-Structure - a Structure that includes the selection settings according to the exchange scheme.
//  Array of fields-Array-an array containing the names of register fields.
//  Structureparameters of exchange settings-Structure - a structure containing exchange settings.
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication -the exchange node for which data is selected.
//
// Returns:
//  ValueTable - A table of values containing data register entries selected according to the terms of the exchange scheme.
//
Function InformationRegisterEntries(ObjectDetails, Filter_Settings, Fields, ExchangeSettings_, ExchangeNode)

	// We select the data taking into account the selections defined in the exchange settings.
	QueryText = GetRequestTextForSelectingInformationRegisterFields(ObjectDetails.ObjectName,
																		ObjectDetails.TableName,
																		Fields,
																		False);
																		
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Ref", Undefined);
	ParametersStructure.Insert("Changes", False);
	ParametersStructure.Insert("ExchangeNode", ExchangeNode);
	ParametersStructure.Insert("MessageNo", Undefined);
	ParametersStructure.Insert("UseAdditionalSelections", True);
	
	Query = GetRequestForObject(QueryText,
									  ObjectDetails,
									  Filter_Settings,
									  ExchangeSettings_,
									  ParametersStructure);
	
	Return Query.Execute().Unload();

EndFunction

// Generates and returns a set of data register entries formed from the transmitted data.
//
// Parameters:
//  ObjectName - String - name of the information register.
//  The key-string combination of value Tables is a row in the value table whose properties contain the values of the recordset fields.
//  ArrayOfRecordTableRows - Array - an array containing rows of a table of values with case entries.
//  KeyFieldsArray - Array - an array containing the names of key fields in the information register.
//  FieldArray - Array - an array containing the field names of the information register.
//
// Returns:
//  ValueTable - A table of values containing data register entries selected according to the terms of the exchange scheme.
//
Function CreateSetOfRecordsToUpload(ObjectName, KeyCombination, ArrayOfRecordTableRows, KeyFieldsArray, FieldArray, SelectedFieldsArray)

	RecordSet = InformationRegisters[ObjectName].CreateRecordSet();

	For Each KeyField In KeyFieldsArray Do
		If SelectedFieldsArray.Find(KeyField) = Undefined Then
			DimensionType = Metadata.InformationRegisters[ObjectName].Dimensions[KeyField].Type;
			FilterValue = DimensionType.AdjustValue();
			RecordSet.Filter[KeyField].Set(FilterValue, True);
		Else
			RecordSet.Filter[KeyField].Set(KeyCombination[KeyField], True);
		EndIf;
	EndDo;

	For Each RowOfRecordTable In ArrayOfRecordTableRows Do
		Record = RecordSet.Add();
		For Each Field In FieldArray Do
			Try
				Record[Field] = RowOfRecordTable[Field];
			Except
				DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
		
				MessageText = ErrorInfo().Description;
				WriteLogEvent(NStr("vi = 'Lỗi tạo gói trao đổi';
									|ru = 'Ошибка при формировании пакета обмена';
									|en = 'An error occurred when generating the exchange pack'; fa = 'An error occurred when generating the exchange pack';
									|it = 'Errore durante la creazione del pacchetto di scambio';
									|pl = 'Błąd podczas utworzenia pakietu wymiany';
									|tr = 'Değişim paketi oluşturulurken hata oluştu'", DefaultLanguageCode),
								EventLogLevel.Error,
								,
								,
								MessageText);
			EndTry;
		EndDo;
	EndDo;

	Return RecordSet;

EndFunction

// Generates and returns a table of values with rows containing unique combinations
// of data register field values that can be used to set selections for record sets.
//
// Parameters:
//  Object descriptionstructure - Structure - a structure containing a description of the metadata object (Name, table name, etc.).
//  selection Structureconstruction - Structure - a structure containing selection settings.
//  Structureparameters of exchange settings-Structure - a structure containing exchange settings.
//  Changes - Boolean - indicates that only changes are selected from the change table.
//  MessageNo - Number - the number of the exchange message within which the data is being sampled.
//
// Returns:
//  ValueTable - A table of values containing unique sets of data register field values.
//
Function RecordsetKeys(ObjectDetails, Filter_Settings, Fields, ExchangeSettings_, Changes = False, ExchangeNode = Undefined, MessageNo = Undefined)

	QueryText = GetRequestTextForSelectingInformationRegisterFields(ObjectDetails.ObjectName,
																		ObjectDetails.TableName,
																		Fields,
																		Changes,
																		MessageNo);
																		
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Ref", Undefined);
	ParametersStructure.Insert("Changes", Changes);
	ParametersStructure.Insert("ExchangeNode", ExchangeNode);
	ParametersStructure.Insert("MessageNo", MessageNo);
	ParametersStructure.Insert("UseAdditionalSelections", False);
	
	Query = GetRequestForObject(QueryText,
									  ObjectDetails,
									  Filter_Settings,
									  ExchangeSettings_,
									  ParametersStructure);

	QueryResult = Query.Execute();
	
	Return QueryResult.Unload();

EndFunction

// Generates and returns a set of records for the specified data register.
// In this case, the selection for a set of records is set based on the specified values of the combination of selection fields.
//
// Parameters:
//  ObjectDescriptionStructure_ - Structure - a structure containing a description of the metadata object.
//  KeyCombination - ValueTableRow - a row in the value table that contains the values of the selection fields.
//  FieldArray - Array - an array containing the names of the register fields for which the selection is set.
//
// Returns:
//  InformationRegisterRecordSet - A set of records with set selections.
//
Function GetSetOfInformationRegisterRecordsByKeyCombination(ObjectDescriptionStructure_, KeyCombination, FieldArray, SelectedFieldsArray)

	RecordSet = InformationRegisters[ObjectDescriptionStructure_.ObjectName].CreateRecordSet();
	
	For Each Field In FieldArray Do

		FilterElement = RecordSet.Filter.Find(Field);
		If FilterElement <> Undefined Then
			If SelectedFieldsArray.Find(Field) = Undefined Then
				DimensionType = Metadata.InformationRegisters[ObjectDescriptionStructure_.ObjectName].Dimensions[Field].Type;
				FilterValue = DimensionType.AdjustValue();
				FilterElement.Set(FilterValue, True);
			Else
				FilterElement.Set(KeyCombination[Field], True);
			EndIf;
		EndIf;

	EndDo;

	Return RecordSet;

EndFunction

// Generates and returns the query text based on object data of a certain type, taking into account
// the fields that will be selected.
//
// Parameters:
// ObjectDescriptionStructure_ - Structure - structure containing the object description.
//  StructureOfExchangeSettings - Structure - structure that contains the configuration settings of exchange.
//
// Returns:
//  String - the generated request text.
//
Function GetRequestTextForFetchingReferenceData(ObjectDescriptionStructure_, StructureOfExchangeSettings)

	// For reference books and documents.
	ClassName = ObjectDescriptionStructure_.ClassName;
	ObjectName = ObjectDescriptionStructure_.ObjectName;
	TableName = ObjectDescriptionStructure_.TableName;

	ArrayOfSelectionFields_ = DataExchangeWithMobileApplicationsEvents.SelectionFieldsForObject(ClassName, ObjectName);

	QueryText = GetRequestTextForMapItem(ObjectName, TableName, ArrayOfSelectionFields_, StructureOfExchangeSettings);

	If QueryText <> "" Then
		Return QueryText;
	EndIf;
	As = " AS "; //@Query-part
	RequestStart = "SELECT ALLOWED "; //@Query-part
	QueryText = RequestStart + ObjectName + ".Ref FROM " + TableName + As
	 + ObjectName + " WHERE NOT " + ObjectName + ".DeletionMark ";

	AddSelectionFieldsToQueryText(QueryText, ArrayOfSelectionFields_);
	
	Return QueryText;

EndFunction

// Generates and returns the query text for selecting fields in the information register.
// Various combinations of the specified fields are selected.
//
// Parameters:
//  ObjectName - String - name of the information register.
//  TableName - String - Name of the table from which the selection is made.
//  FieldArray - Array - an array containing the names of the register fields to be sampled.
//  Changes - Boolean - indicates that only changes are selected from the change table.
//  MessageNo - Number - number of the exchange message. Used while querying the change tables.
//
// Returns:
//  String - the generated request text.
//
Function GetRequestTextForSelectingInformationRegisterFields(ObjectName, TableName, FieldArray, Changes = False, MessageNo = Undefined)
	
	QueryText = GetRequestTextForRegister(ObjectName, TableName, FieldArray, Changes, MessageNo);

	If QueryText <> "" Then
		Return QueryText;
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED
	|	&QueryFields
	|FROM
	|	&TableName AS Table"
	;
	
	FieldsString = "";
	
	FieldsCount = FieldArray.Count();

	If FieldsCount > 0 Then	

		IndexOf = 0;

		For Each Field In FieldArray Do
			
			FieldsString = FieldsString + "Table." + Field;

			If IndexOf < FieldsCount-1 Then
				FieldsString = FieldsString + ",";
			EndIf;	
			
			IndexOf = IndexOf + 1;
			
		EndDo;

	EndIf;

	QueryText = StrReplace(QueryText, "&QueryFields", FieldsString);
	QueryText = StrReplace(QueryText, "&TableName", TableName);
	
	If Changes Then
		ArrayOfSelectionFields_ = New Array();
		ArrayOfSelectionFields_.Add("Node");
		
		If MessageNo <> Undefined Then
			ArrayOfSelectionFields_.Add("MessageNo");
		EndIf;	
	Else
		ArrayOfSelectionFields_ = DataExchangeWithMobileApplicationsEvents.SelectionFieldsForObject("InformationRegisters", ObjectName);
	EndIf;
	
	AddSelectionFieldsToQueryText(QueryText, ArrayOfSelectionFields_);
	
	Return QueryText;
	
EndFunction

// Generates and returns the query text for selecting data for a specific object.
//
// Parameters:
//  ObjectName - String - name of the object to use for generating the request text.
//  TableName - String - name of the data table to use for generating the query text.
//  ArrayOfSelectionFields_ - Array - an array containing the names of fields that can participate in the selection.
//  StructureOfExchangeSettings - Structure - structure that contains the configuration settings of exchange.
//
// Returns:
//  String - The text of the request, if it is defined for the object. Otherwise, an empty string is returned - the
//  "standard" query text for the table will be used, without additional conditions.
//
Function GetRequestTextForMapItem(ObjectName, TableName, ArrayOfSelectionFields_, StructureOfExchangeSettings)

	QueryText = "";
	
	If TableName = "Catalog.Partners" Then
		
		QueryText =
		"SELECT ALLOWED
		|	Partners.Ref AS Ref
		|FROM
		|	Catalog.Partners AS Partners
		|WHERE
		|	Partners.Client
		|	AND Partners.ServedBySalesRepresentatives
		|	AND (NOT Partners.DeletionMark)"
		;
		
	ElsIf TableName = "Catalog.Companies" Then
		
		QueryText =
		"SELECT ALLOWED
		|	Companies.Ref AS Ref
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.Ref <> VALUE(Catalog.Companies.ManagementCompany)"
		;
		
	ElsIf TableName = "Catalog.ContactInformationKinds" Then
		
		QueryText =
		"SELECT ALLOWED
		|	ContactInformationKinds.Ref AS Ref
		|FROM
		|	Catalog.ContactInformationKinds AS ContactInformationKinds
		|WHERE
		|	(ContactInformationKinds.Ref IN HIERARCHY (VALUE(Catalog.ContactInformationKinds.CatalogPartners))
		|			OR ContactInformationKinds.Ref IN HIERARCHY (VALUE(Catalog.ContactInformationKinds.CatalogContactPersonsForPartners)))
		|	AND (NOT ContactInformationKinds.DeletionMark)"
		;	
		
	ElsIf TableName = "Catalog.TypesOfPrices" Then
		
		QueryText =
		"SELECT ALLOWED
		|	TypesOfPrices.Ref AS Ref
		|FROM
		|	Catalog.TypesOfPrices AS TypesOfPrices
		|WHERE
		|	TypesOfPrices.UseWhileSellingToCustomers
		|	AND (NOT TypesOfPrices.DeletionMark)"
		;	
		
	ElsIf TableName = "Catalog.PackagesAndUnitsOfMeasure" Then
		
		QueryText = 
		"SELECT ALLOWED
		|	ProductPackages.Ref AS Ref
		|FROM
		|	Catalog.Products AS Products
		|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
		|		ON (ProductPackages.Owner = Products.Ref),
		|	Catalog.PackagingGroups AS PackagingGroups
		|WHERE
		|	(NOT ProductPackages.Ref IS NULL )
		|	AND (NOT CAST(ProductPackages.Owner AS Catalog.Products) IS NULL )
		|	AND (NOT ProductPackages.DeletionMark)
		|{WHERE
		|	ProductPackages.Owner.*}
		|
		|UNION
		|
		|SELECT
		|	ProductPackages.Ref
		|FROM
		|	Catalog.PackagingGroups AS PackagingGroups
		|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
		|		ON (ProductPackages.Owner = PackagingGroups.Ref)
		|WHERE
		|	(NOT ProductPackages.Ref IS NULL )
		|	AND (NOT CAST(ProductPackages.Owner AS Catalog.PackagingGroups) IS NULL )
		|	AND (NOT ProductPackages.DeletionMark)"
		;
		
	ElsIf TableName = "Catalog.ItemsCharacteristics" Then	
		
		QueryText = 
		"SELECT ALLOWED
		|	ItemsCharacteristics.Ref AS Ref
		|FROM
		|	Catalog.Products AS Products
		|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
		|		ON (ItemsCharacteristics.Owner = Products.Ref),
		|	Catalog.ItemKinds AS ItemKinds
		|WHERE
		|	(NOT ItemsCharacteristics.Ref IS NULL )
		|	AND (NOT CAST(ItemsCharacteristics.Owner AS Catalog.Products) IS NULL )
		|	AND (NOT ItemsCharacteristics.DeletionMark)
		|{WHERE
		|	ItemsCharacteristics.Owner.*}
		|
		|UNION ALL
		|
		|SELECT
		|	ItemsCharacteristics.Ref
		|FROM
		|	Catalog.ItemKinds AS ItemKinds
		|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
		|		ON (ItemsCharacteristics.Owner = ItemKinds.Ref)
		|WHERE
		|	(NOT ItemsCharacteristics.Ref IS NULL )
		|	AND (NOT CAST(ItemsCharacteristics.Owner AS Catalog.ItemKinds) IS NULL )
		|	AND (NOT ItemsCharacteristics.DeletionMark)";
		
	ElsIf TableName = "Catalog.TermsOfSale" Then
		
		QueryText = 	 
		"SELECT ALLOWED
		|	AgreementWithClientIsIndividual.Ref AS Ref
		|FROM
		|	Catalog.TermsOfSale AS AgreementWithClientIsIndividual
		|WHERE
		|   (&UseTermsOfSales <> VALUE(Enum.UseTermsOfSales.OnlyStandardTermsOfSales))
		|	AND AgreementWithClientIsIndividual.UsedInSalesRepresentativesWork
		|	AND AgreementWithClientIsIndividual.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
		|	AND (NOT AgreementWithClientIsIndividual.Standard_)
		|	AND (NOT AgreementWithClientIsIndividual.DeletionMark)
		|{WHERE
		|	AgreementWithClientIsIndividual.Partner}
		|
		|UNION ALL
		|
		|SELECT
		|	StandardAgreementWithClient.Ref
		|FROM
		|	Catalog.TermsOfSale AS StandardAgreementWithClient
		|WHERE
		|   (&UseTermsOfSales <> VALUE(Enum.UseTermsOfSales.OnlySpecialTermsOfSales))
		|	AND StandardAgreementWithClient.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
		|	AND StandardAgreementWithClient.UsedInSalesRepresentativesWork
		|	AND StandardAgreementWithClient.Standard_
		|	AND (NOT StandardAgreementWithClient.DeletionMark)"
		;
		
	ElsIf TableName = "Catalog.CounterpartyContracts" Then
		
		QueryText = 	 
		"SELECT ALLOWED
		|	CounterpartyContracts.Ref AS Ref
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
		|	AND (NOT CounterpartyContracts.DeletionMark)
		|	AND (CounterpartyContracts.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|			OR CounterpartyContracts.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent))
		|{WHERE
		|	CounterpartyContracts.Partner}"
		;
		
	ElsIf TableName = "Catalog.ProductsAttachedFiles" Then
		
		QueryText = 
		"SELECT ALLOWED
		|	Products.PicturesFile AS Ref
		|FROM
		|	Catalog.Products AS Products
		|WHERE
		|	Products.PicturesFile <> VALUE(Catalog.ProductsAttachedFiles.EmptyRef)
		|	AND (NOT Products.DeletionMark)
		|	AND (NOT Products.IsFolder)
		|{WHERE
		|	Products.Ref.*}"
		;
		
	ElsIf TableName = "Document.JobForSalesRepresentative" Then
		
		QueryText = 
		"SELECT ALLOWED
		|	JobForSalesRepresentative.Ref AS Ref
		|FROM
		|	Document.JobForSalesRepresentative AS JobForSalesRepresentative
		|WHERE
		|	JobForSalesRepresentative.SalesRepresentative = &SalesRepresentative
		|	AND JobForSalesRepresentative.Status = VALUE(Enum.SalesRepresentativeTaskStatuses.ToProcessing)
		|	AND (NOT JobForSalesRepresentative.DeletionMark)"
		
		;

	EndIf;

	// Let's add fields for which selection is possible.
	AddSelectionFieldsToQueryText(QueryText, ArrayOfSelectionFields_);
	
	Return QueryText;

EndFunction

// Adds fields that can be selected to the passed request text.
//
// Parameters:
//  QueryText - String - the text of the query that you want to add fields.
//  ArrayOfSelectionFields_ - Array - an array containing the names of the fields to be selected.
//
Procedure AddSelectionFieldsToQueryText(QueryText, ArrayOfSelectionFields_)
	
	If QueryText <> "" Then
		
		NumberOfSelectionFields = ArrayOfSelectionFields_.Count();
		
		If NumberOfSelectionFields > 0 Then
			
			ExtensionText = " {WHERE ";
			
			IndexOf = 0;
			
			For Each Field In ArrayOfSelectionFields_ Do
				
				ExtensionText = ExtensionText + Field;
				
				If IndexOf < NumberOfSelectionFields-1 Then
					ExtensionText = ExtensionText + ",";
				EndIf;	
				
				IndexOf = IndexOf + 1;
				
			EndDo;
			
			ExtensionText = ExtensionText + "}";
			QueryText = QueryText + ExtensionText;
			
		EndIf;
		
	EndIf;

EndProcedure

// Generates and returns a request based on the passed request text
// and the settings structure containing selections for the object.
//
// Parameters:
//  QueryText - String - query text.
//  ObjectDescriptionStructure_ - Structure - structure containing the object description.
//  StructureOfSelectionSettings - Structure - a structure containing the selection settings for the exchange.
//  StructureOfExchangeSettings - Structure - structure that contains the configuration settings of exchange.
//  AdditionalParameters - Structure - structure containing additional parameters
//
// Returns:
//  Query - The generated request.
//
Function GetRequestForObject(QueryText, ObjectDescriptionStructure_, StructureOfSelectionSettings, StructureOfExchangeSettings, AdditionalParameters)

 	ClassName = ObjectDescriptionStructure_.ClassName;
	ObjectName = ObjectDescriptionStructure_.ObjectName;

	CompositionSchema = GetLayoutOfDataForSelection(QueryText);
	CompositionSettings = ComposeSettings(CompositionSchema);

	AddSelectionsFromExchangeScheme(CompositionSettings,
								StructureOfSelectionSettings,
								ClassName,
								ObjectName,
								AdditionalParameters.UseAdditionalSelections,
								StructureOfExchangeSettings,
								True);

	If AdditionalParameters.Ref <> Undefined Then
									
		AddSelectionElementToSchemaSettings(CompositionSettings,
											"Ref",
											DataCompositionComparisonType.Equal,
											True,
											AdditionalParameters.Ref);
	EndIf;

	If AdditionalParameters.Changes Then
		
		AddSelectionElementToSchemaSettings(CompositionSettings,
											"Node",
											DataCompositionComparisonType.Equal,
											True,
											AdditionalParameters.ExchangeNode);
		
		If AdditionalParameters.MessageNo <> Undefined Then
			AddSelectionElementToSchemaSettings(CompositionSettings,
												"MessageNo",
												DataCompositionComparisonType.Equal,
												True,
												AdditionalParameters.MessageNo);
		EndIf;
		
	EndIf;
	
	Template = DataCompositionServer.GetLayoutTemplate(CompositionSchema, CompositionSettings);
	
	Query = DataCompositionServer.GETRequestFromLayoutTemplate(Template, "Query");

	AddRequestParameters(Query, ClassName, ObjectName, StructureOfExchangeSettings);

	Return Query;

EndFunction

// Adds parameters to the passed request for the specified object.
//
// Parameters:
//  Query - Query - the query that you want to add parameters.
//  ClassName - String - name of the class to which the object belongs (Directories, Documents, etc.) for which the query is used.
//  ObjectName - String - name of the metadata object that the request is being used for.
//  StructureOfExchangeSettings - Structure - a structure containing the settings of the exchange parameters.
//
Procedure AddRequestParameters(Query, ClassName, ObjectName, StructureOfExchangeSettings)

	If ClassName = "Catalogs" Then
		If ObjectName = "TermsOfSale" Then
			Query.SetParameter("UseTermsOfSales", StructureOfExchangeSettings.UseTermsOfSales);
		EndIf;
	ElsIf ClassName = "Documents" Then
		If ObjectName = "JobForSalesRepresentative" Then
			Query.SetParameter("SalesRepresentative", StructureOfExchangeSettings.SalesRepresentative);
		EndIf;
	ElsIf ClassName = "InformationRegisters" Then
		If ObjectName = "ExchangeRates" Then
			Query.SetParameter("CurrentDate", CurrentSessionDate());
		EndIf;
	EndIf;

EndProcedure

// Determines whether the use of a specific object is disabled by a functional option, or by other conditions.
//
// Parameters:
//  ClassName - String - name of the class that the object belongs to (Directories, Documents, etc.).
//  ObjectName - String - name of the object to check for an exception.
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication - the exchange plan node for which the exchange is being performed or changes are being registered.
//
// Returns:
//  Boolean - Indicates that usage is disabled. True - use is disabled, False - object is in use.
//
Function ObjectUsageDisabled(ClassName, ObjectName, ExchangeNode)
	
	If ClassName = "Catalogs" Then
		
		If ObjectName = "ProductPackages" Or ObjectName = "PackagingGroups" Then
			Return Not GetFunctionalOption("UseItemPackages");
		ElsIf ObjectName = "ItemsCharacteristics" Then
			Return Not GetFunctionalOption("UseItemVariants");
		ElsIf ObjectName = "PriceGroups" Then
			Return Not GetFunctionalOption("UsePriceGroups");
		ElsIf ObjectName = "ContactPersonsForPartners" Then
			UseContactDetails = Common.ObjectAttributeValue(ExchangeNode, "UseContactDetails");
			Return (UseContactDetails = Enums.ContactDetailsUsageByMobileApplication.NotUsed);
		ElsIf ObjectName = "PaymentSchedules" Then
			Return Not GetFunctionalOption("UsePaymentSchedules");
		ElsIf ObjectName = "ReasonsForSaleOrderCancellation" Then
			Return Not GetFunctionalOption("UseReasonsForSalesOrderCancellations");
		ElsIf ObjectName = "CounterpartyContracts" Then
			Return Not GetFunctionalOption("UseCustomerContracts");
		EndIf;
		
	ElsIf ClassName = "Documents" Then	
		
		If ObjectName = "JobForSalesRepresentative" Then
			UsingTasks = Constants.UseJobsToSalesRepresentatives.Get();
			Return (UsingTasks = Enums.UseJobsToSalesRepresentatives.NotUsed_)
					Or (Not ValueIsFilled(UsingTasks));
		EndIf;
			
	EndIf;
	
	Return False;

EndFunction

#EndRegion

#Region ProceduresAndFunctionsForWorkingWithDataLayout

// Generates and returns a data layout scheme based on the query text
// for selecting data for a specific object.
//
// Parameters:
//  QueryText - String - the text of the query to data source layout.
//
// Returns:
//  DataCompositionSchema - the circuit layout data.
//
Function GetLayoutOfDataForSelection(QueryText)

	CompositionSchema = New DataCompositionSchema();
	
	Source = CompositionSchema.DataSources.Add();
	Source.Name = "Source1";
	Source.ConnectionString="";
	Source.DataSourceType = "local";
	
	DataSet = CompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.Query = QueryText;
	DataSet.Name = "Query";
	DataSet.AutoFillAvailableFields = True;
	DataSet.DataSource = "Source1";
	
	Return CompositionSchema;

EndFunction

// Generates and returns the data layout scheme for the object.
//
// Parameters:
//  FieldArray - Array - an array containing field names.
//
// Returns:
//  DataCompositionSchema - the circuit layout data.
//
Function GetDataLayoutDiagramForObject(FieldArray)

	CompositionSchema = New DataCompositionSchema();
	
	Source = CompositionSchema.DataSources.Add();
	Source.Name = "Source1";
	Source.ConnectionString="";
	Source.DataSourceType = "local";
	
	DataSet = CompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetObject"));
	DataSet.Name = "Object";
	DataSet.ObjectName = "DataObject";
	DataSet.DataSource = "Source1";
	
	For Each Field In FieldArray Do
		DataSetField = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
		DataSetField.Field = Field;
		DataSetField.DataPath = Field;
	EndDo;
	
	Return CompositionSchema;

EndFunction

// Fills in an element in the passed selection based on the structure containing the selection data.
//
// Parameters:
//  Filter - DataCompositionFilter - selection of the data layout to be filled in.
//  Structure of the selection element - Structure - a structure containing data for filling in the selection element.
//  FilterElementName - String - name of the selection element field.
//
Procedure FillInLayoutSelectionElementFromStructure(Filter, StructureOfSelectionSettings, SettingName, FilterElementName)

	StructureOfSelectionElement = DescriptionOfSelectionToConfigure(StructureOfSelectionSettings, SettingName);

	If StructureOfSelectionElement = Undefined Then
		Return;
	EndIf;
		
	FilterElement = Filter.Items.Add(Type("DataCompositionFilterItem"));
	
	For Each Item In StructureOfSelectionElement Do
		If Item.Key = "LeftValue" Then
			FilterElement[Item.Key] =  New DataCompositionField(FilterElementName);
		Else
			FilterElement[Item.Key] = Item.Value;
		EndIf;
	EndDo;

EndProcedure

// Adds selections to the layout settings for individual objects.
//
// Parameters:
//  ObjectAttributeStructure - Structure - structure containing the object's details.
//  Filter - DataCompositionFilter - the selection of the layout element for which you want to fill.
//  StructureOfSelectionSettings - Structure - a structure containing a description of the selection to be set.
//  ClassName - String - name of the class that the object belongs to (reference Books, Documents, etc.).
//  ObjectName - String - the name of the object to which are added selections.
//
Procedure AddSelectionsForIndividualObjects(ObjectAttributeStructure, Filter, StructureOfSelectionSettings, ClassName, ObjectName)
	
	If ClassName = "Catalogs" Then
		
		If ObjectName = "ProductPackages" Or ObjectName = "ItemsCharacteristics" Then
			FillInSelectionElementForPackagingAndProductCharacteristics(ObjectAttributeStructure, Filter, StructureOfSelectionSettings);
		EndIf;
		
		If ObjectName = "TermsOfSale" Then
			FillInSelectionElementForClientAgreement(ObjectAttributeStructure, Filter, StructureOfSelectionSettings);
		EndIf;
		
	EndIf;
	
EndProcedure	

// Fills in the selection element for the "packaging Nomenclature" and "characteristics of Nomenclature" reference books.
//
// Parameters:
//  ObjectAttributeStructure - Structure - structure containing the object's details.
//  Filter - DataCompositionFilter - the selection of the layout element for which you want to fill.
//  StructureOfSelectionSettings - Structure - a structure containing a description of the selection to be set.
//
Procedure FillInSelectionElementForPackagingAndProductCharacteristics(ObjectAttributeStructure, Filter, StructureOfSelectionSettings)
	
	If TypeOf(ObjectAttributeStructure.Owner) = Type("CatalogRef.Products") Then
		
		StructureOfSelectionElement = DescriptionOfSelectionToConfigure(StructureOfSelectionSettings, "Products");
		
		If StructureOfSelectionElement = Undefined Then
			Return;
		EndIf;
		
		FilterElement = Filter.Items.Add(Type("DataCompositionFilterItem"));
		
		For Each Item In StructureOfSelectionElement Do
			If Item.Key = "LeftValue" Then
				FilterElement[Item.Key] =  New DataCompositionField("Owner");
			Else
				FilterElement[Item.Key] = Item.Value;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

// Fills in the selection element for the "agreements with Clients"directory.
//
// Parameters:
//  ObjectAttributeStructure - Structure - structure containing the object's details.
//  Filter - DataCompositionFilter - the selection of the layout element for which you want to fill.
//  StructureOfSelectionSettings - Structure - a structure containing a description of the selection to be set.
//
Procedure FillInSelectionElementForClientAgreement(ObjectAttributeStructure, Filter, StructureOfSelectionSettings)
	
	If Not ObjectAttributeStructure.Standard_ Then
		
		StructureOfSelectionElement = DescriptionOfSelectionToConfigure(StructureOfSelectionSettings, "Partner");
		
		If StructureOfSelectionElement = Undefined Then
			Return;
		EndIf;
		
		FilterElement = Filter.Items.Add(Type("DataCompositionFilterItem"));
		
		For Each Item In StructureOfSelectionElement Do
			If Item.Key = "LeftValue" Then
				FilterElement[Item.Key] =  New DataCompositionField("Partner");
			Else
				FilterElement[Item.Key] = Item.Value;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

// Sets mandatory selections for selecting objects using layout, which are imposed regardless of user settings.
//
// Parameters:
//  CompositionSettings - DataCompositionSettings - customize the layout data for which to set the selection.
//  ClassName - String - name of the class that the object belongs to (reference Books, Documents, etc.).
//  ObjectName - String - the name of the metadata object to which are added selections.
//  StructureOfExchangeSettings - Structure - structure that contains the configuration settings of exchange.
//
Procedure AddMandatorySelections(CompositionSettings, ClassName, ObjectName, StructureOfExchangeSettings)

	If ClassName = "Catalogs" Then

		If ObjectName = "Partners" Then
			
			AddSelectionElementToSchemaSettings(CompositionSettings, "Client", DataCompositionComparisonType.Equal, True, True);
			AddSelectionElementToSchemaSettings(CompositionSettings, "ServedBySalesRepresentatives", DataCompositionComparisonType.Equal, True, True);
			
		ElsIf ObjectName = "Companies" Then
			
			AddSelectionElementToSchemaSettings(CompositionSettings, "Ref", DataCompositionComparisonType.NotEqual, True, Catalogs.Companies.ManagementCompany);
			
		ElsIf ObjectName = "TermsOfSale" Then
			
			AddSelectionElementToSchemaSettings(CompositionSettings, "Status", DataCompositionComparisonType.Equal, True, Enums.StatusesOfTermsOfSales.Valid);
			AddSelectionElementToSchemaSettings(CompositionSettings, "UsedInSalesRepresentativesWork", DataCompositionComparisonType.Equal, True, True);
			
			If StructureOfExchangeSettings.UseTermsOfSales = Enums.UseTermsOfSales.OnlyStandardTermsOfSales Then
				AddSelectionElementToSchemaSettings(CompositionSettings, "Standard_", DataCompositionComparisonType.Equal, True, True);
			EndIf;
			
			If StructureOfExchangeSettings.UseTermsOfSales = Enums.UseTermsOfSales.OnlySpecialTermsOfSales Then
				AddSelectionElementToSchemaSettings(CompositionSettings, "Standard_", DataCompositionComparisonType.Equal, True, False);
			EndIf;
			
		ElsIf ObjectName = "CounterpartyContracts" Then
			
			AddSelectionElementToSchemaSettings(CompositionSettings, "Status", DataCompositionComparisonType.Equal, True, Enums.CounterpartyContractStatuses.Valid);
			
			BusinessTransactionList = New ValueList();
			BusinessTransactionList.Add(Enums.BusinessTransactions.SaleToCustomer);
			BusinessTransactionList.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
			
			AddSelectionElementToSchemaSettings(CompositionSettings, "BusinessOperation", DataCompositionComparisonType.InList, True, BusinessTransactionList);
			
		ElsIf ObjectName = "ContactInformationKinds" Then
			
			ListOfGroupsUsed = New ValueList();
			ListOfGroupsUsed.Add(Catalogs.ContactInformationKinds.CatalogPartners);
			ListOfGroupsUsed.Add(Catalogs.ContactInformationKinds.CatalogContactPersonsForPartners);
			
			AddSelectionElementToSchemaSettings(CompositionSettings, "Ref", DataCompositionComparisonType.InListByHierarchy, True, ListOfGroupsUsed);
			
		EndIf;
		
	ElsIf ClassName = "Documents" Then

		If ObjectName = "JobForSalesRepresentative" Then
			AddSelectionElementToSchemaSettings(CompositionSettings, "Status", DataCompositionComparisonType.Equal, True, Enums.SalesRepresentativeTaskStatuses.ToProcessing);
			AddSelectionElementToSchemaSettings(CompositionSettings, "SalesRepresentative", DataCompositionComparisonType.Equal, True, StructureOfExchangeSettings.SalesRepresentative);
		EndIf;

	EndIf;

EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForWorkingWithExchangeSettingsAndParameters

// Gets and returns a structure containing a selection description for the specified exchange setting.
//
// Parameters:
//  Selection structureconstruction-Structure - a structure containing the selection settings for the exchange scheme.
//  SettingName - String - name of the setting in the selection settings structure.
//
// Returns:
//  Structure - A structure containing a description of the selection for the specified exchange setting.
//
Function DescriptionOfSelectionToConfigure(Filter_Settings, SettingName)

	Setting = Undefined;
	If Filter_Settings.Property(SettingName, Setting) Then
		If TypeOf(Setting) = Type("Structure") Then
			Return Setting;
		EndIf;
	EndIf;

	Return Setting;

EndFunction

#EndRegion

#Region MetadataProceduresAndFunctions

// Generates and returns the structure for using the directory property (a prop or table part).
//
// Parameters:
//  Property - Arbitrary - a property of the metadata object is an attribute or a tabular section of the Handbook.
//
// Returns:
//  Structure - The structure of the use of a property that defines the use for an element and a group of the directory.
//
Function UsingCatalogProperty(Property)

	// Let's define the use case.
	ForItem = (Property.Use <> Metadata.ObjectProperties.AttributeUse.ForFolder);
	ForFolder   = (Property.Use <> Metadata.ObjectProperties.AttributeUse.ForItem);

	UsageStructure = New Structure();
	UsageStructure.Insert("UsedForElement", ForItem);
	UsageStructure.Insert("UsedForGroup", ForFolder);

	Return UsageStructure;

EndFunction

Function GetIndicationOfTypeOfBankingDetails(Attribute)

	If Attribute.Type.Types().Count()>1 Then
		Return XMLTypeAssignment.Explicit;
	Else
		Return XMLTypeAssignment.Implicit;
	EndIf;

EndFunction

// Defines and returns the type of standard object (reference or document) details.
//
// Parameters:
//  MetadataObject - MetadataObjectCatalog, MetadataObjectDocument - the metadata object that the prop belongs to.
//  ClassName - String - name of the class to which the object belongs (reference Books, Documents).
//  AttributeName - String - name of the prop that you want to determine the type of.
//
// Returns:
//  Type - The type of the prop.
//
Function GetTypeOfStandardProps(MetadataObject, ClassName, AttributeName)

	AttributeType = Undefined;
	
	If AttributeName = "Ref" Or AttributeName = "Ref" Then
		
		If ClassName = "Catalogs" Then
			AttributeType = Type("CatalogRef." + MetadataObject.Name);
		Else
			AttributeType = Type("DocumentRef." + MetadataObject.Name);
		EndIf;
		
	ElsIf AttributeName = "IsFolder" Or AttributeName = "IsFolder"
		Or AttributeName = "DeletionMark" Or AttributeName = "DeletionMark"
		Or AttributeName = "Posted" Or AttributeName = "Posted" Then
		
		AttributeType = Type("Boolean");
		
	ElsIf AttributeName = "Parent" Or AttributeName = "Parent" Then
		
		AttributeType = Type("CatalogRef." + MetadataObject.Name);
		
	ElsIf AttributeName = "Description" Or AttributeName = "Description" Then
		
		AttributeType = Type("String");
		
	ElsIf AttributeName = "Date" Or AttributeName = "Date" Then
		
		AttributeType = Type("Date");
		
	ElsIf AttributeName = "Code" Or AttributeName = "Code" Then
		
		If MetadataObject.CodeType = Metadata.ObjectProperties.CatalogCodeType.String Then
			AttributeType = Type("String");
		Else
			AttributeType = Type("Number");
		EndIf;
			
	ElsIf AttributeName = "Number" Or AttributeName = "Number" Then
		
		If MetadataObject.NumberType = Metadata.ObjectProperties.DocumentNumberType.String Then
			AttributeType = Type("String");
		Else
			AttributeType = Type("Number");
		EndIf;
		
	EndIf;
	
	Return AttributeType;

EndFunction

Function GetTypeOfProps(Attribute)

	TypeDescription = Attribute.Type;
	TypesArray = TypeDescription.Types();
	
	If TypesArray.Count()=1 Then
		Return TypesArray[0];
	Else
		Return Undefined;
	EndIf;

EndFunction

// Generates and returns the structure of the description of the metadata object's props.
//
// Parameters:
//  MetadataObject - MetadataObjectCatalog, MetadataObjectDocument - the metadata object whose details are being analyzed.
//  AttributeName - String - name of the prop to be used.
//
// Returns:
//  Structure - A structure describing the usage (for a group and an element) and specifying the type of the directory's props.
//
Function DescriptionOfCatalogDetails(MetadataObject, AttributeName)

	AttributeType = Undefined;
	
	If AttributeName = "Ref" Or AttributeName = "Ref"
		Or AttributeName = "IsFolder" Or AttributeName = "IsFolder"
		Or AttributeName = "DeletionMark" Or AttributeName = "DeletionMark"
		Or AttributeName = "Parent" Or AttributeName = "Parent"
		Or AttributeName = "Code" Or AttributeName = "Code"
		Or AttributeName = "Description" Or AttributeName = "Description" Then

		ForItem = True;
		ForFolder = True;
		TypeIndication = XMLTypeAssignment.Implicit;
		
		AttributeType = GetTypeOfStandardProps(MetadataObject, "Catalogs", AttributeName);

	ElsIf AttributeName = "Owner" Or AttributeName = "Owner" Then

		ForItem = True;
		ForFolder = True;
		TypeIndication = XMLTypeAssignment.Explicit;
		
	ElsIf AttributeName = "Predefined" Or AttributeName = "Predefined" Then

		ForItem = True;
		ForFolder = True;
		TypeIndication = XMLTypeAssignment.Implicit;
		AttributeType = Type("Boolean");
		
	Else
		
		Attribute = MetadataObject.Attributes[AttributeName];
		AttributeType = GetTypeOfProps(Attribute);
		
		// Let's determine the use case of the props.
		UsageStructure = UsingCatalogProperty(Attribute);

		ForItem = UsageStructure.UsedForElement;
		ForFolder   = UsageStructure.UsedForGroup;
		
		// Let's define a variant of specifying the type for the props.
		// The type should be specified only if it cannot always be uniquely determined.
		
		TypeIndication = GetIndicationOfTypeOfBankingDetails(Attribute);
		
	EndIf;

	DetailsStructure1 = New Structure();
	DetailsStructure1.Insert("UsedForElement", ForItem);
	DetailsStructure1.Insert("UsedForGroup", ForFolder);
	DetailsStructure1.Insert("TypeIndication", TypeIndication);
	DetailsStructure1.Insert("Type", AttributeType);

	Return DetailsStructure1;

EndFunction

// Generates and returns the structure of the description of the metadata object's props.
//
// Parameters:
//  MetadataObject - MetadataObjectCatalog, MetadataObjectDocument - the metadata object whose details are being analyzed.
//  AttributeName - String - name of the prop to be used.
//
// Returns:
//  Structure - A structure describing the indication of the type of document details.
//
Function DescriptionOfDocumentDetails(MetadataObject, AttributeName)

	AttributeType = Undefined;
	
	If AttributeName = "Ref" Or AttributeName = "Ref"
		Or AttributeName = "DeletionMark" Or AttributeName = "DeletionMark"
		Or AttributeName = "Date" Or AttributeName = "Date"
		Or AttributeName = "Number" Or AttributeName = "Number"
		Or AttributeName = "Posted" Or AttributeName = "Posted" Then

		TypeIndication = XMLTypeAssignment.Implicit;
		
		AttributeType = GetTypeOfStandardProps(MetadataObject, "Documents", AttributeName);
		
	Else
		
		Attribute = MetadataObject.Attributes[AttributeName];
		AttributeType = GetTypeOfProps(Attribute);
		
		// Let's define a variant of specifying the type for the props.
		// The type should be specified only if it cannot always be uniquely determined.
		TypeIndication = GetIndicationOfTypeOfBankingDetails(Attribute);
		
	EndIf;

	DetailsStructure1 = New Structure();
	DetailsStructure1.Insert("TypeIndication", TypeIndication);
	DetailsStructure1.Insert("Type", AttributeType);

	Return DetailsStructure1;

EndFunction

// Creates and returns a structure that reflects the composition of the metadata object (reference or document).
// The structure contains the following elements: Details-an array of object details, tabular Parts-a structure of table parts.
//
// Parameters:
//  MetadataObject - MetadataObjectCatalog, MetadataObjectDocument - the metadata object whose composition structure you want to get.
//  ClassName - String - name of the object class (reference Books, Documents, etc.).
//  ObjectName - String - the name of the metadata object.
//  TreeOfMetadataUsed - See MobileApps.UsedMetadata
//
// Returns:
//  Structure - structure that describes the object's composition.
//
Function ItemDescription_(MetadataObject, ClassName, ObjectName, TreeOfMetadataUsed)

	CompositionStructure = New Structure();
	AttributesStructure1 = New Structure();
	
	StructureOfTableParts = New Structure();

	ClassString = TreeOfMetadataUsed.Rows[0].Rows.Find(ClassName, "Name");

	If ClassString = Undefined Then
		
		#If ExternalConnection Then
		MessageText = NStr("vi = 'Trong gói trao đổi ghi dữ liệu sai: %ClassName%.%ObjectName%.%Linefeed%Trong ứng dụng không sử dụng %ClassName%';
							|ru = 'В пакет обмена записаны неверные данные: %ClassName%.%ObjectName%.%Linefeed%В приложении не используются %ClassName%';
							|en = 'Invalid data is in the exchange package: %ClassName%.%ObjectName%.%Linefeed% %ClassName% is not used in the application'; fa = 'Invalid data is in the exchange package: %ClassName%.%ObjectName%.%Linefeed% %ClassName% is not used in the application';
							|it = 'I dati non corretti vengono scritti nel pacchetto di scambio: %ClassName%.%ObjectName%.%Linefeed% L''applicazione non è in uso %ClassName%';
							|pl = 'Do pakietu wymiany są zapisane błędne dane: %ClassName%.%ObjectName%.%Linefeed%W aplikacji nie są stosowane %ClassName%';
							|tr = 'Değişim paketine yanlış veriler kaydedildi: %ClassName%.%ObjectName%.%Linefeed%Uygulamada %ClassName% kullanmıyor'");
		MessageText = StrReplace(MessageText,"%ClassName%",ClassName);
		MessageText = StrReplace(MessageText,"%ObjectName%",ObjectName);
		MessageText = StrReplace(MessageText,"%Linefeed%",Chars.LF);
		
		Raise(MessageText);
		#EndIf
		
	EndIf;

	ObjectString = ClassString.Rows.Find(ObjectName, "Name");

	If ObjectString = Undefined Then
		
		#If ExternalConnection Then
		MessageText = NStr("vi = 'Trong gói trao đổi ghi dữ liệu sai: %ClassName%.%ObjectName%.%Linefeed%Trong ứng dụng không sử dụng đối tượng này';
							|ru = 'В пакет обмена записаны неверные данные: %ClassName%.%ObjectName%.%Linefeed%В приложении не используется данный объект';
							|en = 'Invalid data is in exchange package: %ClassName%.%ObjectName%.%Linefeed% This object is not used in the application'; fa = 'Invalid data is in exchange package: %ClassName%.%ObjectName%.%Linefeed% This object is not used in the application';
							|it = 'I dati non corretti vengono scritti nel pacchetto di scambio: %ClassName%.%ObjectName%.%Linefeed% L''applicazione non è in uso questo oggetto';
							|pl = 'Do pakietu wymiany są zapisane błędne dane: %ClassName%.%ObjectName%.%Linefeed%W aplikacji nie jest używany dany obiekt';
							|tr = 'Değişim paketine yanlış veriler kaydedildi: %ClassName%.%ObjectName%.%Linefeed%Uygulamada mevcut veri kullanılmıyor'");
		MessageText = StrReplace(MessageText,"%ClassName%",ClassName);
		MessageText = StrReplace(MessageText,"%ObjectName%",ObjectName);
		MessageText = StrReplace(MessageText,"%Linefeed%",Chars.LF);
		
		Raise(MessageText);
		#EndIf
		
	EndIf;
	
	// Add the details of the object.
	PropsBranch = ObjectString.Rows.Find("Attributes","Name");
	
	If PropsBranch <> Undefined Then
		For Each PropsString In PropsBranch.Rows Do
			
			PropsDescriptionStructure = New Structure();
					
			If ClassName = "Catalogs" Then
				PropsDescriptionStructure = DescriptionOfCatalogDetails(MetadataObject, PropsString.Name);
			ElsIf ClassName = "Documents" Then
				PropsDescriptionStructure = DescriptionOfDocumentDetails(MetadataObject, PropsString.Name);
			EndIf;

			AttributesStructure1.Insert(PropsString.Name, PropsDescriptionStructure);

		EndDo;	
	EndIf;	
	
	// Let's add the details of the table parts.
	
	BranchTableParts = ObjectString.Rows.Find("TabularParts","Name");
	
	If BranchTableParts <> Undefined Then
		
		For Each LineOfATabularSection In BranchTableParts.Rows Do

			StructureOfTablePartDescription = New Structure();
			StructureOfDetailsOfTablePart = New Structure();
			
			TabularSectionName = LineOfATabularSection.Name;
			
			For Each PropsString In LineOfATabularSection.Rows Do

				PropsDescriptionStructure = New Structure();

				TabularSectionAttribute = MetadataObject.TabularSections[TabularSectionName].Attributes[PropsString.Name];
				TypeIndication = GetIndicationOfTypeOfBankingDetails(TabularSectionAttribute);
				AttributeType = GetTypeOfProps(TabularSectionAttribute);

				PropsDescriptionStructure.Insert("TypeIndication", TypeIndication);
				PropsDescriptionStructure.Insert("Type", AttributeType);

				StructureOfDetailsOfTablePart.Insert(PropsString.Name, PropsDescriptionStructure);

			EndDo;
			
			TabularSection = MetadataObject.TabularSections[TabularSectionName];

			If ClassName = "Catalogs" Then
				
				StructureOfUsingTablePart = UsingCatalogProperty(TabularSection);
				
				StructureOfTablePartDescription.Insert("UsedForElement", StructureOfUsingTablePart.UsedForElement);
				StructureOfTablePartDescription.Insert("UsedForGroup", StructureOfUsingTablePart.UsedForGroup);
				
			EndIf;
			
			StructureOfTablePartDescription.Insert("AttributesStructure1", StructureOfDetailsOfTablePart);

			StructureOfTableParts.Insert(TabularSectionName, StructureOfTablePartDescription);
			
		EndDo;
		
	EndIf;
	
	CompositionStructure.Insert("Attributes", AttributesStructure1);
	CompositionStructure.Insert("TabularSections", StructureOfTableParts);
		
	Return CompositionStructure;

EndFunction

// Generates and returns a structure containing a description of the objects used.
//
// Parameters:
//  ExchangeNode - ExchangePlanRef.SalesRepresentativeMobileApplication- the exchange plan node for which the objects used are analyzed.
//
// Returns:
//  Structure - A structure containing a description of the objects used.
//
Function DescriptionOfObjectsUsed(ExchangeNode)

	DetailsStructure1 = New Structure();

	DescriptionOfMetadataUsed = Common.ObjectAttributeValue(ExchangeNode, "MobileApplicationVersion.UsedMetadata");
	TreeOfMetadataUsed = UsedMetadata(DescriptionOfMetadataUsed);

	RootOfMetadataTree = TreeOfMetadataUsed.Rows[0];

	For Each ClassString In RootOfMetadataTree.Rows Do

		ClassName = ClassString.Name;

		If ClassName = "Constants" Or ClassName = "Catalogs" Or ClassName = "Documents" Or ClassName = "InformationRegisters" Then

			ClassMetadata = Metadata[ClassName];
			
			For Each ObjectString In ClassString.Rows Do
				
				ObjectMetadata = ClassMetadata[ObjectString.Name];
				
				ObjectDescriptionStructure_ = DataExchangeWithMobileApplicationsEvents.ObjectDetails(ObjectMetadata, False);
				
				If ObjectDescriptionStructure_.ClassName = "Catalogs" Or ObjectDescriptionStructure_.ClassName = "Documents" Then
					CompositionStructure = ItemDescription_(ObjectMetadata, ObjectDescriptionStructure_.ClassName, ObjectDescriptionStructure_.ObjectName, TreeOfMetadataUsed);
					DetailsStructure1.Insert(ObjectDescriptionStructure_.ClassName + ObjectDescriptionStructure_.ObjectName, CompositionStructure);
				EndIf;
				
			EndDo;

		EndIf;

	EndDo;

	Return DetailsStructure1;

EndFunction

// Retrieves and returns an array containing the names of key fields in the information register,
// i.e. fields that participate in the main selection and must be filled
// in when registering changes.
//
// Parameters:
//  MetadataObject - MetadataObjectInformationRegister - metadata object of a specific data register.
//
// Returns:
//  Array - An array containing the names of key register fields.
//
Function KeyFieldsOfInformationRegister(MetadataObject)

	FieldArray = New Array();

	// For registers of information subordinate to the registrar, selection is possible only by the registrar.
	If MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate Then
		FieldArray.Add("Recorder");
		Return FieldArray;
	EndIf;
	
	If MetadataObject.MainFilterOnPeriod Then
		FieldArray.Add("Period");
	EndIf;

	For Each Dimension In MetadataObject.Dimensions Do
		If Dimension.MainFilter Then
			FieldArray.Add(Dimension.Name);
		EndIf;
	EndDo;

	Return FieldArray;

EndFunction

// Gets and returns an array containing the names of fields in the information register.
//
// Parameters:
//  MetadataObject - MetadataObjectInformationRegister - metadata object of a specific data register
//
// Returns:
//  Array - an array containing the names of the register fields.
//
Function InformationRegisterFieldsForSelection(MetadataObject)

	FieldArray = KeyFieldsOfInformationRegister(MetadataObject);
	
	For Each StandardAttribute In MetadataObject.StandardAttributes Do
		If FieldArray.Find(StandardAttribute.Name) = Undefined Then
			FieldArray.Add(StandardAttribute.Name);
		EndIf;
	EndDo;

	For Each Dimension In MetadataObject.Dimensions Do
		If FieldArray.Find(Dimension.Name) = Undefined Then
			FieldArray.Add(Dimension.Name);
		EndIf;
	EndDo;
	
	For Each Resource In MetadataObject.Resources Do
		FieldArray.Add(Resource.Name);
	EndDo;
	
	For Each Attribute In MetadataObject.Attributes Do
		FieldArray.Add(Attribute.Name);
	EndDo;

	Return FieldArray;

EndFunction

#EndRegion

#EndRegion
