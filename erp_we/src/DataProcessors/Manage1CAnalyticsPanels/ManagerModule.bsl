#If Server Or ThickClientOrdinaryApplication Then

#Region Public

// Download panel data from 1C:Analytics.
// 
// Parameters:
//  Parameters - See DataProcessors.Manage1CAnalyticsPanels.UpdateParametersFromAnalytics
// 
// Returns:
//  See DataProcessors.Manage1CAnalyticsPanels.UpdateParametersFromAnalytics
Function UploadPanelData(Parameters) Export
	
	UploadOwners(Parameters.OwnersOfAnalytics);
	LoadPanels(Parameters.Panels);
	
	FoldersFromSchema = FoldersFromSchema();
	ObjectIdsOfAllPanels = New Map(); // to exclude deleted objects
	
	Panels = Parameters.Panels;
	For Each Panel In Panels Do 
		IdsOfSubmittedObjects = New Map();
		
		FillInIdsOfSubmittedObjects(FoldersFromSchema, Panel.Data_RootFolderId, IdsOfSubmittedObjects);
		
		For Each Id In IdsOfSubmittedObjects Do
			ObjectIdsOfAllPanels.Insert(Id.Key, True);
			IdsOfSubmittedObjectsPanel = Panel.IdsOfSubmittedObjects;// ValueList
			IdsOfSubmittedObjectsPanel.Add(Id.Key);
		EndDo;
	EndDo;
	
	UploadFolders(Parameters.Folders, ObjectIdsOfAllPanels);
	DownloadCharts(Parameters.Charts, ObjectIdsOfAllPanels);
	LoadDashboards(Parameters.Dashboards, ObjectIdsOfAllPanels);
	LoadAnalyticsObjects(Parameters.AnalyticsObjects);
	
	Return Parameters;
	
EndFunction

// Update parameters from analytics.
// 
// Returns:
//  Structure - Update Parameters From Analytics:
// * OwnersOfAnalytics - Undefined, List of values
// * Dashboards - Undefined, Assignment tables
// * Charts - Undefined, Assignment tables
// * AnalyticsObjects - Undefined, Assignment tables
// * Panels - Undefined, Assignment tables
// * Folders - Undefined, Assignment tables
Function UpdateParametersFromAnalytics() Export
	
	Structure = New Structure();
	Structure.Insert("OwnersOfAnalytics", Undefined);
	Structure.Insert("Dashboards", Undefined);
	Structure.Insert("Charts", Undefined);
	Structure.Insert("AnalyticsObjects", Undefined);
	Structure.Insert("Panels", Undefined);
	Structure.Insert("Folders", Undefined);
	
	Return Structure;
	
EndFunction

// Load source panels from JSON.
// 
// Parameters:
//  Parameters - See DataProcessors.Manage1CAnalyticsPanels.ParametersReadingFromFile
// 
// Returns:
//  See DataProcessors.Manage1CAnalyticsPanels.ParametersReadingFromFile
Function LoadSourcePanelsFromJSON(Parameters) Export
	
	ParametersReadingFromFile = Parameters.ParametersReadingFromFile;
	
	ClearTable = True;
	
	For Each Desktop In Parameters.Content Do

		DesktopData = JSONValue(Desktop);
		
		ArrayOfOwners = New Array();
		ArrayOfDesktops = New Array();
		FoldersArray = New Array();
		ArrayOfCharts = New Array();
		ArrayOfDashboards = New Array();
		ArrayOfAnalyticsObjects = New Array();
		
		For Each Item In DesktopData Do
			ObjectType = Item.Get("type");
			If ObjectType = "user" Then
				ArrayOfOwners.Add(Item);
			ElsIf ObjectType = "desktop" Then
				ArrayOfDesktops.Add(Item);
			ElsIf ObjectType = "folder" Then
				FoldersArray.Add(Item);
			ElsIf ObjectType = "chart" Then
				ArrayOfCharts.Add(Item);
			ElsIf ObjectType = "dashboard" Then
				ArrayOfDashboards.Add(Item);
			Else
				ArrayOfAnalyticsObjects.Add(Item);
			EndIf;

			If ParametersReadingFromFile.PanelSettingsIds <> Undefined Then
				IndexOf = Parameters.Content.Find(Desktop);
				RowTableIdentifiers = ParametersReadingFromFile.PanelSettingsIds[IndexOf];
				RowTableIdentifiers.ElementIds.Add(Item["id"]);
			EndIf;
		EndDo;
		
		UploadOwners(ParametersReadingFromFile.OwnersOfAnalyticsFromFile, ArrayOfOwners, ClearTable);
		LoadPanels(ParametersReadingFromFile.PanelsFromFile, ArrayOfDesktops, ClearTable);
		
		Panels = ParametersReadingFromFile.PanelsFromFile;
		For Each Panel In Panels Do 
			IdsOfSubmittedObjects = New Map();
			
			FillInIdsOfSubmittedObjects(FoldersArray, Panel.Data_RootFolderId, IdsOfSubmittedObjects);
			
			For Each Id In IdsOfSubmittedObjects Do
				IdsOfSubmittedObjectsPanel = Panel.IdsOfSubmittedObjects;// ValueList
				IdsOfSubmittedObjectsPanel.Add(Id.Key);
			EndDo;
		EndDo;
		
		LoadAnalyticsObjects(ParametersReadingFromFile.AnalyticsObjectsFromFile, ArrayOfAnalyticsObjects, ClearTable);
		UploadFolders(ParametersReadingFromFile.FoldersFromFile, Undefined, FoldersArray, ClearTable);
		DownloadCharts(ParametersReadingFromFile.DiagramsFromFile, Undefined, ArrayOfCharts, ClearTable);
		LoadDashboards(ParametersReadingFromFile.DashboardsFromFile, Undefined, ArrayOfDashboards, ClearTable);
		
		ClearTable = False;
		
	EndDo;
	
	Return ParametersReadingFromFile;
	
EndFunction

// Parameters read from a file.
// 
// Returns:
//  Structure - Parameters Reading From A File:
// * OwnersOfAnalyticsFromFile - Undefined, List of values
// * DashboardsFromFile - Undefined, Assignment tables
// * DiagramsFromFile - Undefined, Assignment tables
// * AnalyticsObjectsFromFile - Undefined, Assignment tables
// * PanelsFromFile - Undefined, Assignment tables
// * FoldersFromFile - Undefined, Assignment tables
// * PanelSettingsIds - Undefined, Assignment tables
Function ParametersReadingFromFile() Export
	
	Structure = New Structure();
	Structure.Insert("OwnersOfAnalyticsFromFile", Undefined);
	Structure.Insert("DashboardsFromFile", Undefined);
	Structure.Insert("DiagramsFromFile", Undefined);
	Structure.Insert("AnalyticsObjectsFromFile", Undefined);
	Structure.Insert("PanelsFromFile", Undefined);
	Structure.Insert("FoldersFromFile", Undefined);
	Structure.Insert("PanelSettingsIds", Undefined);
	
	Return Structure;
	
EndFunction

// Creates a link to the panel from the source.
// 
// Parameters:
//  Parameters - See DataProcessors.Manage1CAnalyticsPanels.RefCreationParameters
// 
// Returns:
//  See DataProcessors.Manage1CAnalyticsPanels.RefCreationParameters
Function CreateLinkToPanel(Parameters) Export
	
	ObjectID = Parameters.ObjectID; 
	SelectedOwnersReceiver = Parameters.SelectedOwnersReceiver;
	SourcePanels = Parameters.SourcePanels;
	Panels = Parameters.Panels;
	
	SelectedObject = SourcePanels.Rows.Find(ObjectID, "Id", True); //ValueTreeRow
	
	For Each Panel In Panels Do
		
		If SelectedOwnersReceiver.FindByValue(Panel.OwnerName) = Undefined Then
			Continue;
		EndIf;
		
		ConnectToPanel(Panel, SelectedObject, Parameters);
		
	EndDo;
	
	Return UploadPanelData(Parameters);;
	
EndFunction

// Link creation parameters.
// 
// Returns:
//  Structure - Link Creation Parameters:
// * SelectedOwnersReceiver - Undefined, List of values
// * ObjectID - String
// * SourcePanels - Undefined, Assignment tables
// * Panels - Undefined, Assignment tables
// * Dashboards - Undefined, Assignment tables
// * Charts - Undefined, Assignment tables
// * Folders - Undefined, Assignment tables
// * OwnersOfAnalytics - Undefined, Assignment tables
// * AnalyticsObjects - Undefined, Assignment tables
Function RefCreationParameters() Export
	
	Structure = New Structure();
	Structure.Insert("SelectedOwnersReceiver", Undefined);
	Structure.Insert("ObjectID", "");
	Structure.Insert("SourcePanels", Undefined);
	Structure.Insert("Panels", Undefined);
	Structure.Insert("Dashboards", Undefined);
	Structure.Insert("Charts", Undefined);
	Structure.Insert("Folders", Undefined);
	Structure.Insert("OwnersOfAnalytics", Undefined);
	Structure.Insert("AnalyticsObjects", Undefined);
	
	Return Structure;
	
EndFunction

// Creates a link to the panel from the source.
// 
// Parameters:
//  Parameters - See DataProcessors.Manage1CAnalyticsPanels.RefsCreationParameters
// 
// Returns:
//  See DataProcessors.Manage1CAnalyticsPanels.RefsCreationParameters
Function CreateLinksOnPanel(Parameters) Export
	
	LinksToOwners = AllObjectsToCreateLink(Parameters);
	CreateLinks(LinksToOwners, Parameters.OwnersOfAnalytics, Parameters.Folders);
	Return UploadPanelData(Parameters);
	
EndFunction

// Link creation parameters.
// 
// Returns:
//  Structure - Link Creation Parameters:
// * SelectedOwnersReceiver - Undefined, List of values
// * SourcePanels - Undefined, Assignment tables
// * Panels - Undefined, Assignment tables
// * Dashboards - Undefined, Assignment tables
// * Charts - Undefined, Assignment tables
// * Folders - Undefined, Assignment tables
// * OwnersOfAnalytics - Undefined, Assignment tables
// * AnalyticsObjects - Undefined, Assignment tables
Function RefsCreationParameters() Export
	
	Structure = New Structure();
	Structure.Insert("SelectedOwnersReceiver", Undefined);
	Structure.Insert("SourcePanels", Undefined);
	Structure.Insert("Panels", Undefined);
	Structure.Insert("Dashboards", Undefined);
	Structure.Insert("Charts", Undefined);
	Structure.Insert("Folders", Undefined);
	Structure.Insert("OwnersOfAnalytics", Undefined);
	Structure.Insert("AnalyticsObjects", Undefined);
	
	Return Structure;
	
EndFunction

// Copies the panel from the source.
// 
// Parameters:
//  Parameters - See DataProcessors.Manage1CAnalyticsPanels.OptionsForCopyingPanels
// 
// Returns:
//  See DataProcessors.Manage1CAnalyticsPanels.UpdateParametersFromAnalytics
Function CopyPanel(Parameters) Export
	
	ObjectID = Parameters.ObjectID; 
	OwnerNameOfNewPanels = Parameters.SelectedOwner;
	
	FromFile = Parameters.FromFile;
	OwnersOfAnalytics = Parameters.OwnersOfAnalytics;
	SelectedOwnersReceiver = Parameters.SelectedOwnersReceiver;
	SourcePanels = Parameters.SourcePanels;
	Panels = Parameters.Panels;
	AnalyticsObjectsSource = Parameters.AnalyticsObjectsSource;
	Folders = Parameters.Folders;
	AdditionalSources = Parameters.AdditionalSources;
	PanelSettingsIds = Parameters.PanelSettingsIds;
	ServerAddress = Parameters.ServerAddress;
	
	SelectedObject = SourcePanels.Rows.Find(ObjectID, "Id", True);
	
	If SelectedObject.Type = "folder" And FromFile Then
		TransfersByOwner = AllObjectsToTransfer(Parameters, SelectedObject, OwnerNameOfNewPanels);
		TransferObjectsFromFile(TransfersByOwner, OwnersOfAnalytics, AnalyticsObjectsSource, Folders,
			AdditionalSources, PanelSettingsIds, ServerAddress, FromFile);
	Else
		
		If FromFile Then
			FoundPanel = Panels.Find(OwnerNameOfNewPanels, "OwnerName");
			CreateAndConnectToPanel(FoundPanel, SelectedObject, Parameters);
		EndIf;
		
		For Each Panel In Panels Do
			If FromFile Then
				If SelectedOwnersReceiver.FindByValue(Panel.OwnerName) = Undefined
					Or Panel.OwnerName = OwnerNameOfNewPanels Then
					Continue;
				EndIf;
				
				ConnectToPanel(Panel, SelectedObject, Parameters); 
			Else
				If SelectedOwnersReceiver.FindByValue(Panel.OwnerName) = Undefined Then
					Continue;
				EndIf;
				
				CreateAndConnectToPanel(Panel, SelectedObject, Parameters);
			EndIf;
		EndDo;
		
	EndIf;
	
	Return UploadPanelData(Parameters);
	
EndFunction

// Options for copying panels.
// 
// 
// Returns:
//  Structure - Options For Copying Panels:
// * ObjectID - String
// * SelectedOwner - String
// * FromFile - Boolean
// * SelectedOwnersReceiver - Undefined, List of values
// * SourcePanels - Undefined, Assignment tables
// * Panels - Undefined, Assignment tables
// * Dashboards - Undefined, Assignment tables
// * Charts - Undefined, Assignment tables
// * Folders - Undefined, Assignment tables
// * OwnersOfAnalytics - Undefined, Assignment tables
// * AnalyticsObjects - Undefined, Assignment tables
// * DashboardsSource - Undefined, Assignment tables
// * SourceCharts - Undefined, Assignment tables
// * SourceFolders - Undefined, Assignment tables
// * AnalyticsObjectsSource - Undefined, Assignment tables
// * IdsToOverwrite - Undefined, List of values
Function OptionsForCopyingPanels() Export
	
	Structure = New Structure();
	
	Structure.Insert("ObjectID", "");
	Structure.Insert("SelectedOwner", "");
	
	Structure.Insert("FromFile", False);
	Structure.Insert("SelectedOwnersReceiver", Undefined);
	Structure.Insert("SourcePanels", Undefined);
	Structure.Insert("Panels", Undefined);
	Structure.Insert("Dashboards", Undefined);
	Structure.Insert("Charts", Undefined);
	Structure.Insert("Folders", Undefined);
	Structure.Insert("OwnersOfAnalytics", Undefined);
	Structure.Insert("AnalyticsObjects", Undefined);
	Structure.Insert("DashboardsSource", Undefined);
	Structure.Insert("SourceCharts", Undefined);
	Structure.Insert("SourceFolders", Undefined);
	Structure.Insert("AnalyticsObjectsSource", Undefined);
	Structure.Insert("IdsToOverwrite", Undefined);
	Structure.Insert("AdditionalSources", Undefined);
	Structure.Insert("PanelSettingsIds", Undefined);
	Structure.Insert("ServerAddress", "");
	
	Return Structure;
	
EndFunction

// removes the panel from the source.
// 
// Parameters:
//  Parameters - See DataProcessors.Manage1CAnalyticsPanels.PanelRemovalOptions
// 
// Returns:
//  See DataProcessors.Manage1CAnalyticsPanels.PanelRemovalOptions
Function DeletePanel(Parameters) Export
	
	RowID = Parameters.RowID; 
	Panels = Parameters.Panels;
	ReceiverPanels = Parameters.ReceiverPanels;
	
	SelectedObject = ReceiverPanels.Rows.Find(RowID, "RowID", True); //ValueTreeRow
	Panel = FindByID(Panels, SelectedObject.PanelOwner, "Owner");
	
	ReadyForProcessing_ = TreeRowsToBeProcessed(ReceiverPanels, RowID, "RowID");
	
	For Each Object In ReadyForProcessing_ Do
		
		DeleteFromPanel(Panel, Object, Parameters);
		
	EndDo;
	
	Return UploadPanelData(Parameters);
	
EndFunction

// Link creation parameters.
// 
// Returns:
//  Structure - Link Creation Parameters:
// * SelectedOwnersReceiver - Undefined, List of values
// * RowID - String
// * SourcePanels - Undefined, Assignment tables
// * Panels - Undefined, Assignment tables
// * Dashboards - Undefined, Assignment tables
// * Charts - Undefined, Assignment tables
// * Folders - Undefined, Assignment tables
// * OwnersOfAnalytics - Undefined, Assignment tables
// * AnalyticsObjects - Undefined, Assignment tables
Function PanelRemovalOptions() Export
	
	Structure = New Structure();
	Structure.Insert("SelectedOwnersReceiver", Undefined);
	Structure.Insert("RowID", "");
	Structure.Insert("SourcePanels", Undefined);
	Structure.Insert("ReceiverPanels", Undefined);
	Structure.Insert("Panels", Undefined);
	Structure.Insert("Dashboards", Undefined);
	Structure.Insert("Charts", Undefined);
	Structure.Insert("Folders", Undefined);
	Structure.Insert("OwnersOfAnalytics", Undefined);
	Structure.Insert("AnalyticsObjects", Undefined);
	
	Return Structure;
	
EndFunction

// JSON panel settings.
// 
// Parameters:
//  OwnersOfAnalytics - ValueList of String - Owners of Analytics
//  Panels - ValueTable - Panels
//  Folders - ValueTable - Folders
//  Charts - ValueTable - Charts
//  Dashboards - ValueTable - Dashboards
//  AnalyticsObjects - ValueTable - Analytics Objects
// 
// Returns:
//  String - JSON Panel Settings
Function JSONPanelSettings(OwnersOfAnalytics, Panels, Folders, Charts, Dashboards, AnalyticsObjects) Export
	
	SettingsArray = New Array();
	
	For Each Owner In OwnersOfAnalytics Do
		FieldsOfUser = OwnerFields(Owner);
		SettingsArray.Add(FieldsOfUser);
	EndDo;
	
	For Each Panel In Panels Do
		DesktopFields = PanelFields(Panel);
		SettingsArray.Add(DesktopFields);
	EndDo;
	
	For Each Folder In Folders Do
		FolderFields = FolderFields(Folder);
		SettingsArray.Add(FolderFields);
	EndDo;
	
	For Each Chart In Charts Do
		ChartFields = ChartFields(Chart);
		SettingsArray.Add(ChartFields);
	EndDo;
	
	For Each Dashboard In Dashboards Do
		DashboardFields = DashboardFields(Dashboard);
		SettingsArray.Add(DashboardFields);
	EndDo;
	
	For Each Item In AnalyticsObjects Do
		FieldsOfAnalyticsObject = FieldsOfAnalyticsObject(Item);
		SettingsArray.Add(FieldsOfAnalyticsObject);
	EndDo;
	
	AdditionalJSONSources = ValueToJSON(SettingsArray);
	
	Return AdditionalJSONSources;
	
EndFunction

// Settings of the selected JSON owners.
// 
// Parameters:
//  Panels - ValueTable - Panels
//  SelectedOwnersReceiver - ValueList of String - Selected Owners Receiver
//  OwnersOfAnalytics - ValueTable - Owners of Analytics
//  Folders - ValueTable - Folders
//  Charts - ValueTable - Charts
//  Dashboards - ValueTable - Dashboards
//  AnalyticsObjects - ValueTable - Analytics Objects
// 
// Returns:
//  String - Settings of Selected JSON Owners
Function SettingsOfSelectedJSONOwners(Panels, SelectedOwnersReceiver, OwnersOfAnalytics, Folders, Charts, Dashboards, AnalyticsObjects) Export
	
	SettingsArray = New Array();
	
	For Each Panel In Panels Do
		
		If SelectedOwnersReceiver.FindByValue(Panel.OwnerName) = Undefined Then
			Continue;
		EndIf;
		
		Owner = FindByID(OwnersOfAnalytics, Panel.Owner);
		OwnerFields = OwnerFields(Owner);
		SettingsArray.Add(OwnerFields);
		
		DesktopFields = PanelFields(Panel);
		SettingsArray.Add(DesktopFields);
		
		For Each Item In Panel.IdsOfSubmittedObjects Do
			ObjectID = Item.Value;
			
			Chart = FindByID(Charts, ObjectID);
			If Chart <> Undefined Then
				ChartFields = ChartFields(Chart);
				SettingsArray.Add(ChartFields);
				Continue;
			EndIf;
			
			Dashboard = FindByID(Dashboards, ObjectID);
			If Dashboard <> Undefined Then
				DashboardFields = DashboardFields(Dashboard);
				SettingsArray.Add(DashboardFields);
				Continue;
			EndIf;
			
			Folder = FindByID(Folders, ObjectID);
			If Folder <> Undefined Then
				FolderFields = FolderFields(Folder);
				SettingsArray.Add(FolderFields);
			EndIf
		EndDo;
		
		For Each Item In AnalyticsObjects Do
			If Item.Owner = Panel.Owner Then
				FieldsOfAnalyticsObject = FieldsOfAnalyticsObject(Item);
				SettingsArray.Add(FieldsOfAnalyticsObject);
			EndIf;
		EndDo;
		
	EndDo;

	JSONDesktopSettings = ValueToJSON(SettingsArray);
	
	Return JSONDesktopSettings; 
	
EndFunction

// The parent folder can be moved.
// 
// Parameters:
//  ObjectString - Arbitrary - Object string
//  Transfers_1 - Map of KeyAndValue:
//   * Key - String - transfer option.
//   * Value - Boolean - transfer availability.
// 
// Returns:
//  Boolean - The Parent Folder Can Be Moved
Function ParentFolderCanBeMoved(ObjectString, Transfers_1) Export
	
	If ObjectString.Type = "folder" Then
		Transfer = Transfers_1.Get(ObjectString.Id);
	ElsIf ObjectString.Level() = 1 Then
		Return True;
	Else
		StringOfParentObject = ObjectString.Parent; //ValueTreeRow
		Transfer = Transfers_1.Get(StringOfParentObject.Id);
	EndIf;
	
	If Transfer = Undefined Then
		Return True; // subfolder movement
	EndIf;
	
	If Not Transfer.PossibleAsNew And Not Transfer.PossibleWithSubstitution Then
		Return False;
	EndIf;
	
	If ObjectString.Level() <> 1 Then
		Return ParentFolderCanBeMoved(ObjectString.Parent, Transfers_1);
	EndIf;
	
	Return True;
	
EndFunction

// Find a row by object ID in the table of values.
// 
// Parameters:
//  SearchTable - Undefined - Search table
//  Id - String, Arbitrary - Id
// 
// Returns:
//  Undefined - Find by ID
Function FindByID(SearchTable, Id, FieldForSearch = "Id") Export
	
	SearchResult = SearchTable.FindRows(New Structure(FieldForSearch, Id));
	If SearchResult.Count() Then
		Return SearchResult[0];
	EndIf;
	
	Return Undefined;
	
EndFunction

// Fill in the array of tree rows.
// 
// Parameters:
//  Tree - ValueTree - 
//  RowID - String - row ID
//  FieldForSearch - String - Name of the string search field
// 
// Returns:
//  Array of String - Tree Rows To Be Processed
Function TreeRowsToBeProcessed(Tree, RowID = Undefined, FieldForSearch = "Id") Export

	RowsSelected = New Array;
	If RowID = Undefined Then
		For Each String In Tree.Rows Do
			RowsSelected.Add(String);
		EndDo;
	Else
		TreeRow = Tree.Rows.Find(RowID, FieldForSearch, True);
		RowsSelected.Add(TreeRow);
	EndIf;
	
	RowsArray = New Array;
	
	For Each RowSelected In RowsSelected Do
		FillInArrayOfTreeRows(RowSelected, RowsArray);
	EndDo;
	
	Return RowsArray;
	
EndFunction

// Fill in the array of tree rows.
// 
// Parameters:
//  TreeRow - ValueTreeRow
//  RowsArray - Array of ValueTreeRow- Array of strings
Procedure FillInArrayOfTreeRows(TreeRow, RowsArray) Export
	
	If TreeRow.Id <> "" Then
		RowsArray.Add(TreeRow);
	EndIf;
	
	For Each String In TreeRow.Rows Do
		If String.Id <> "" Then
			RowsArray.Add(String);
		EndIf;
		
		For Each Substring In String.Rows Do
			FillInArrayOfTreeRows(Substring, RowsArray);
		EndDo;
	EndDo;
	
EndProcedure

// Transfers.
// 
// Parameters:
//  ReceiverPanel - ValueTree - Receiver Panel
//  LinesToTransfer - Array of ValueTreeRow - Lines To Transfer
//  FromFile - Boolean - From the file
//  Charts - ValueTable - Charts
//  Dashboards - ValueTable - Dashboards
//  Folders - ValueTable - Folders
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - String - transfer option.
//   * Value - Boolean - transfer availability.
Function Transfers_1(ReceiverPanel, LinesToTransfer, FromFile, Charts, Dashboards, Folders) Export
	
	Transfers_1 = New Map();
	For Each SourceObject In LinesToTransfer Do
	
		If SourceObject = Undefined 
			Or SourceObject.Type <> "chart" And SourceObject.Type <> "dashboard" And SourceObject.Type <> "folder" Then
			Continue;
		EndIf;
		
		Result = TransferAvailability(ReceiverPanel, SourceObject, FromFile, Charts, Dashboards, Folders);
		Transfers_1.Insert(SourceObject, Result);
			
	EndDo;
	
	Return Transfers_1;
	
EndFunction

// Panels from the diagram.
// 
// Parameters:
//  Id - Undefined - Id
// 
// Returns:
//  Array of String, Arbitrary - Panels From The Diagram
Function PanelsFromDiagram(Id = Undefined) Export
	
	Return AnalyticsObjects("desktop", Id);
	
EndFunction 

// Diagrams from the diagram.
// 
// Parameters:
//  Id - Undefined - Id
// 
// Returns:
//  Array of String, Arbitrary - Diagrams From The Diagram
Function DiagramsFromDiagram(Id = Undefined) Export
	
	Return AnalyticsObjects("chart", Id);
	
EndFunction

// Dashboards from the schema.
// 
// Parameters:
//  Id - Undefined - Id
// 
// Returns:
//  Array of String, Arbitrary - Dashboards From The Schema
Function DashboardsFromSchema(Id = Undefined) Export 
	
	Return AnalyticsObjects("dashboard", Id);
	
EndFunction

// Owners from the scheme.
// 
// Parameters:
//  Id - Undefined - Id
// 
// Returns:
//  Array of String, Arbitrary - Owners From The Scheme
Function OwnersFromScheme(Id = Undefined) Export 
	
	Return AnalyticsObjects("user", Id);
	
EndFunction

// Folders from the schema.
// 
// Parameters:
//  Id - Undefined - Id
// 
// Returns:
//  Array of String, Arbitrary - Folders From The Schema
Function FoldersFromSchema(Id = Undefined) Export
	
	Return AnalyticsObjects("folder", Id);
	
EndFunction 

// Analytics objects from the schema.
// 
// Returns:
//  Array of String - Analytics Objects From The Schema
Function AnalyticsObjectsFromSchema() Export
	
	AnalyticsObjectsArray = New Array();
	
	UserFields = AnalyticsObjects("user-field");
	For Each Item In UserFields Do
		AnalyticsObjectsArray.Add(Item);
	EndDo;
	
	ColorSchemes = AnalyticsObjects("colorScheme");
	For Each Item In ColorSchemes Do
		AnalyticsObjectsArray.Add(Item);
	EndDo;
	
	MarkerCards = AnalyticsObjects("markerMap");
	For Each Item In MarkerCards Do
		AnalyticsObjectsArray.Add(Item);
	EndDo;
	
	MapsOfRegions = AnalyticsObjects("areasMap");
	For Each Item In MapsOfRegions Do
		AnalyticsObjectsArray.Add(Item);
	EndDo;
	
	MappingForAreaMaps = AnalyticsObjects("areasMapping");
	For Each Item In MappingForAreaMaps Do
		AnalyticsObjectsArray.Add(Item);
	EndDo;
	
	TileServers = AnalyticsObjects("tileServer");
	For Each Item In TileServers Do
		AnalyticsObjectsArray.Add(Item);
	EndDo; 
	
	Expressions = AnalyticsObjects("globalMacro");
	For Each Item In Expressions Do
		AnalyticsObjectsArray.Add(Item);
	EndDo;
	
	Return AnalyticsObjectsArray;
	
EndFunction

// Additional sources from the scheme.
// 
// Parameters:
//  Id - Undefined - Id
// 
// Returns:
//  Array of String, Arbitrary - Additional Sources From The Scheme
Function AdditionalSourcesFromScheme(Id = Undefined) Export
	
	Return AnalyticsObjects("additional-datasource", Id);
	
EndFunction

// Versions of server formats.
// 
// Parameters:
//  ServerAddress - String - server address
// 
// Returns:
//  Map  of KeyAndValue:
//   * Key - String - name of the version property.
//   * Value - Number - deviation from the expected version
Function ServerFormatVersions(ServerAddress) Export
	
	Versions = New Map();
	Versions.Insert("additional-datasource", -1);
	Versions.Insert("undo", -1);
	Versions.Insert("desktop", -1);
	Versions.Insert("folder", -1);
	Versions.Insert("root", -1);
	Versions.Insert("userField", -1);
	Versions.Insert("chart", -1);
	Versions.Insert("user", -1);
	Versions.Insert("dataSource", -1);
	Versions.Insert("delete", -1);
	Versions.Insert("dashboard", -1);
	
	URIStructure = URIStructure(ServerAddress);
	
	If IsBlankString(URIStructure.ResourceAddress) Or IsBlankString(URIStructure.Host) Then
		Return Versions;
	EndIf;
	
	ResourceAddress = URIStructure.ResourceAddress;
	If Not StrEndsWith(ResourceAddress, "/") Then
		ResourceAddress = ResourceAddress + "/";
	EndIf;
	ResourceAddress = ResourceAddress + "api/ans/version/objects";
	
	EventName = NStr("vi = 'Quản lý hệ thống phân tích';
					|ru = 'Управление системой аналитики';
					|en = 'Analytics system management'; fa = 'مدیریت سیستم تحلیلی';
					|it = 'Управление системой аналитики';
					|pl = 'Analytics system management';
					|tr = 'Boyut sisteminin yönetimi'");
	
	Try
		Proxy = GetFilesFromInternet.GetProxy("https");
		
		If URIStructure.Schema = "https" Then
			SecureConnection = CommonClientServer.NewSecureConnection();
			HTTPConnection = New HTTPConnection(URIStructure.Host, URIStructure.Port,,, Proxy, 60, SecureConnection);
		Else
			HTTPConnection = New HTTPConnection(URIStructure.Host, URIStructure.Port,,, Proxy, 60);
		EndIf;
		//Secure connection = General purpose Client Server.Newly protected connection();
		//NTTR connection = The new NTTR connection(Structururi.Host, structururi.Port,,, Proxy, 60 , Secure connection);
		
		HTTPRequest = New HTTPRequest(ResourceAddress);
		HTTPResponse =  HTTPConnection.Get(HTTPRequest);
	Except
		WriteLogEvent(EventName,
			EventLogLevel.Error, , ,
			ErrorInfo());
		
		Return Versions;
	EndTry;
	
	If HTTPResponse.StatusCode >= 400 And HTTPResponse.StatusCode < 500 Then
		For Each Version In Versions Do
			Version.Value = Version.Value + 1;
		EndDo;
		Versions.Insert("additional-datasource", 1);
		
		Return Versions; // old unsupported version
	ElsIf HTTPResponse.StatusCode <> 200 Then
		WriteLogEvent(EventName,
			EventLogLevel.Error, , ,
			StrTemplate("HTTP status code: %1", HTTPResponse.StatusCode));
		
		Return Versions;
	EndIf;
	
	Try
		Response_String = HTTPResponse.GetBodyAsString();
		ResponseObject = JSONValue(Response_String);
	Except
		Return Versions;
	EndTry;
	
	If TypeOf(ResponseObject) = Type("Map") Then
		Return ResponseObject;
	Else
		For Each Version In Versions Do
			Version.Value = Version.Value + 1;
		EndDo;
		Versions.Insert("additional-datasource", 1);
		Return Versions; // old unsupported version
	EndIf; 
	
EndFunction

// Gets analytics objects.
// 
// Parameters:
//  ObjectType - String - Object type
//  Id - Undefined - Id
// 
// Returns:
//  Array of String, Arbitrary - Analytics Objects
Function AnalyticsObjects(ObjectType, Id = Undefined) Export
	
	Join = AnalyticsSystem.GetConnection();
	Schema = Join.GetSchema("objects", ?(Id = Undefined, New Structure("type", ObjectType), Id));
	
	ObjectsArray = JSONValue(Schema.GetAsString());
	
	Return ObjectsArray;
	
EndFunction

// Writes the scheme to analytics.
// 
// Parameters:
//  Schema - String - Schema
Procedure WriteSchema(Schema) Export 
	
	Join = AnalyticsSystem.GetConnection();
	Join.WriteSchema("objects", New AnalyticsSystemSchema(Schema));
	
EndProcedure

// Removes the schema by ID from analytics.
// 
// Parameters:
//  Id - String - Id
Procedure DeleteSchema(Id) Export
	
	Join = AnalyticsSystem.GetConnection();
	Join.DeleteSchema("objects", Id);
	
EndProcedure

	
#EndRegion

#Region Internal

// URI structure.
// 
// Parameters:
//  Address - String - Address
// 
// Returns:
//  Structure - URI structure:
// * Schema - String - 
// * Host - String - 
// * Port - Number, Undefined - 
// * ResourceAddress - String - 
Function URIStructure(Val Address) Export
	
	Address = TrimAll(Address);
	
	Position = Find(Address, "://");
	Schema = "";
	If Position > 0 Then
		Schema = Lower(Left(Address, Position - 1));
		Address = Mid(Address, Position + 3);
	EndIf;
	
	ResourceAddress = "";
	ServerName = Address;
	Position = Find(Address, "/");
	If Position > 0 Then
		ResourceAddress = Mid(Address, Position + 1);
		ServerName = Left(Address, Position - 1);
	EndIf;
	
	Host = ServerName;
	Port = "";
	Position = Find(ServerName, ":");
	If Position > 0 Then
		Host = Left(ServerName, Position - 1);
		Port = Mid(ServerName, Position + 1);
	EndIf;
	
	Result = New Structure();
	Result.Insert("Schema", Schema);
	Result.Insert("Host", Host);
	Result.Insert("Port", ?(Port <> "", Number(Port), Undefined));
	Result.Insert("ResourceAddress", ResourceAddress);
	
	Return Result;
	
EndFunction

// The value in JSON.
// 
// Parameters:
//  Value - Arbitrary - Value
// 
// Returns:
//  String - Value in JSON
Function ValueToJSON(Value) Export
	
	JSONWriter = New JSONWriter();
	JSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
	WriteJSON(JSONWriter, Value);
	
	Return JSONWriter.Close(); 
	
EndFunction

// JSON value.
// 
// Parameters:
//  JSONString - Undefined, Arbitrary - JSON string
// 
// Returns:
//  Array of String, Arbitrary - JSONValue
Function JSONValue(JSONString) Export
	
	If Not ValueIsFilled(JSONString) Or JSONString = "[]" Then
		Return New Array();
	EndIf;
	JSONReader = New JSONReader();
	JSONReader.SetString(JSONString);
	
	Return ReadJSON(JSONReader, True);
	
EndFunction

#EndRegion

#Region Private

Procedure FillInIdsOfSubmittedObjects(FoldersFromSchema, IDOfCurFolder, IdsOfSubmittedObjects)
	
	For Each Folder In FoldersFromSchema Do
		If Folder.Get("id") = IDOfCurFolder Then
			IdsOfSubmittedObjects.Insert(IDOfCurFolder, True);
			
			DataFolder = Folder.Get("data");
			FolderDataMatching = JSONValue(DataFolder);
			
			FileIdsFolder = FolderDataMatching.Get("fileIds");
			For Each Item In FileIdsFolder Do
				IdsOfSubmittedObjects.Insert(Item, True);
			EndDo;
			
			FolderIdsFolder = FolderDataMatching.Get("folderIds");
			For Each Item In FolderIdsFolder Do
				If IdsOfSubmittedObjects.Get(Item) = Undefined Then // otherwise an infinite loop
					FillInIdsOfSubmittedObjects(FoldersFromSchema, Item, IdsOfSubmittedObjects);
				EndIf;
			EndDo;
			
			Break;
		EndIf;
	EndDo;
	
EndProcedure

Procedure LoadAnalyticsObjects(ObjectsTable, AnalyticsObjectsFromSchema = Undefined, ShouldClearTable = True)
	
	If ShouldClearTable Then
		ObjectsTable.Clear();
	EndIf;
	
	OtherFields = New ValueTable;
	OtherFields.Columns.Add("Key", New TypeDescription("String"));
	OtherFields.Columns.Add("Value");
	
	If AnalyticsObjectsFromSchema = Undefined Then
		AnalyticsObjectsFromSchema = AnalyticsObjectsFromSchema();
	EndIf;
	
	For Each DimensionObject In AnalyticsObjectsFromSchema Do
		If DimensionObject.Get("originalId") <> Undefined Then // Draft
			Continue;
		EndIf;
		
		NewRow = ObjectsTable.Add();
		
		For Each Field In DimensionObject Do
			If Field.Key = "id" Then
				NewRow.Id = Field.Value;
			ElsIf Field.Key = "name" Then
				NewRow.Name = Field.Value;
			ElsIf Field.Key = "owner" Then
				NewRow.Owner = Field.Value;
			ElsIf Field.Key = "type" Then
				NewRow.Type = Field.Value;
			ElsIf Field.Key = "ownerName" Then
				NewRow.OwnerName = Field.Value;
			ElsIf Field.Key = "updated" Then
				NewRow.Updated = Field.Value;
			ElsIf Field.Key = "chartType" Then
				NewRow.ChartType = Field.Value;
			ElsIf Field.Key = "data" Then
				NewRow.Data = Field.Value;
			ElsIf Field.Key = "version" Then
				NewRow.Version = Field.Value;
			ElsIf Field.Key = "links" Then
				NewRow.Links.LoadValues(Field.Value);
			Else
				NewRow.OtherFields = OtherFields;
				TableOtherFields = NewRow.OtherFields; //ValueTable
				OtherField = TableOtherFields.Add();
				OtherField.Key = Field.Key;
				If TypeOf(Field.Value) = Type("Array") Then
					ValueList = New ValueList();
					ValueList.LoadValues(Field.Value);
					OtherField.Value = ValueList;
				Else
					OtherField.Value = Field.Value;
				EndIf;
			EndIf;
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure UploadOwners(OwnersTable, Owners = Undefined, ShouldClearTable = True)
	
	If ShouldClearTable Then
		OwnersTable.Clear();
	EndIf;
	
	OtherFields = New ValueTable;
	OtherFields.Columns.Add("Key", New TypeDescription("String"));
	OtherFields.Columns.Add("Value");
	
	If Owners = Undefined Then
		Owners = OwnersFromScheme();
	EndIf;
	
	For Each Owner In Owners Do
		If Owner.Get("id") = Undefined
			Or Owner.Get("owner") = Undefined
			Or Owner.Get("type") = Undefined
			Or Owner.Get("ownerName") = Undefined
			Or Owner.Get("data") = Undefined Then
			
			Raise NStr("vi = 'Bộ xử lý không hỗ trợ phiên bản sơ đồ dữ liệu';
						|ru = 'Версия схемы данных не поддерживается обработкой';
						|en = 'The ER diagram version is not supported by the data processor'; fa = 'The ER diagram version is not supported by the data processor';
						|it = 'Версия схемы данных не поддерживается обработкой';
						|pl = 'The ER diagram version is not supported by the data processor';
						|tr = 'Veri şeması sürümü veri işlemcisi tarafından desteklenmiyor'")
		EndIf;
		
		NewRow = OwnersTable.Add();
		
		For Each Field In Owner Do
			If Field.Key = "id" Then
				NewRow.Id = Field.Value;
			ElsIf Field.Key = "owner" Then
				NewRow.Owner = Field.Value;
			ElsIf Field.Key = "type" Then
				NewRow.Type = Field.Value;
			ElsIf Field.Key = "ownerName" Then
				NewRow.OwnerName = Field.Value;
			ElsIf Field.Key = "updated" Then
				NewRow.Updated = Field.Value;
			ElsIf Field.Key = "data" Then
				NewRow.Data = Field.Value;
			ElsIf Field.Key = "version" Then
				NewRow.Version = Field.Value;
			ElsIf Field.Key = "links" Then
				NewRow.Links.LoadValues(Field.Value);
			Else
				NewRow.OtherFields = OtherFields;
				TableOtherFields = NewRow.OtherFields; //ValueTable
				OtherField = TableOtherFields.Add();
				OtherField.Key = Field.Key;
				If TypeOf(Field.Value) = Type("Array") Then
					ValueList = New ValueList();
					ValueList.LoadValues(Field.Value);
					OtherField.Value = ValueList;
				Else
					OtherField.Value = Field.Value;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Procedure LoadPanels(PanelTable, PanelsFromDiagram = Undefined, ShouldClearTable = True)
	
	If ShouldClearTable Then
		PanelTable.Clear();
	EndIf;
	
	OtherFields = New ValueTable;
	OtherFields.Columns.Add("Key", New TypeDescription("String"));
	OtherFields.Columns.Add("Value");
	
	If PanelsFromDiagram = Undefined Then
		PanelsFromDiagram = PanelsFromDiagram();
	EndIf;

	For Each ResultingPanel In PanelsFromDiagram Do
		If ResultingPanel.Get("id") = Undefined
			Or ResultingPanel.Get("owner") = Undefined
			Or ResultingPanel.Get("type") = Undefined
			Or ResultingPanel.Get("ownerName") = Undefined
			Or ResultingPanel.Get("data") = Undefined Then
			
			Raise NStr("vi = 'Bộ xử lý không hỗ trợ phiên bản sơ đồ dữ liệu';
						|ru = 'Версия схемы данных не поддерживается обработкой';
						|en = 'The ER diagram version is not supported by the data processor'; fa = 'The ER diagram version is not supported by the data processor';
						|it = 'Версия схемы данных не поддерживается обработкой';
						|pl = 'The ER diagram version is not supported by the data processor';
						|tr = 'Veri şeması sürümü veri işlemcisi tarafından desteklenmiyor'")
		EndIf;
		
		NewRow = PanelTable.Add();
		
		For Each Field In ResultingPanel Do
			If Field.Key = "id" Then
				NewRow.Id = Field.Value;
			ElsIf Field.Key = "owner" Then
				NewRow.Owner = Field.Value;
			ElsIf Field.Key = "type" Then
				NewRow.Type = Field.Value;
			ElsIf Field.Key = "ownerName" Then
				NewRow.OwnerName = Field.Value;
			ElsIf Field.Key = "data" Then
				NewRow.Data = Field.Value;
			ElsIf Field.Key = "version" Then
				NewRow.Version = Field.Value;
			ElsIf Field.Key = "links" Then
				NewRow.Links.LoadValues(Field.Value);
			Else
				NewRow.OtherFields = OtherFields;
				TableOtherFields = NewRow.OtherFields; //ValueTable
				OtherField = TableOtherFields.Add();
				OtherField.Key = Field.Key;
				If TypeOf(Field.Value) = Type("Array") Then
					ValueList = New ValueList();
					ValueList.LoadValues(Field.Value);
					OtherField.Value = ValueList;
				Else
					OtherField.Value = Field.Value;
				EndIf;
			EndIf;
		EndDo;
			
		Desktop_DataMap = JSONValue(NewRow.Data);
		
		If Desktop_DataMap.Get("rootFolderId") = Undefined Then
			Raise NStr("vi = 'Bộ xử lý không hỗ trợ phiên bản sơ đồ dữ liệu';
						|ru = 'Версия схемы данных не поддерживается обработкой';
						|en = 'The ER diagram version is not supported by the data processor'; fa = 'The ER diagram version is not supported by the data processor';
						|it = 'Версия схемы данных не поддерживается обработкой';
						|pl = 'The ER diagram version is not supported by the data processor';
						|tr = 'Veri şeması sürümü veri işlemcisi tarafından desteklenmiyor'");
		EndIf;
		
		NewRow.Data_RootFolderId = Desktop_DataMap.Get("rootFolderId");
	EndDo;
	
	PanelTable.Sort("OwnerName");
	
EndProcedure

Procedure UploadFolders(FoldersTable, IdsOfSubmittedObjects = Undefined, FoldersFromSchema = Undefined, ShouldClearTable = True)

	If ShouldClearTable Then
		FoldersTable.Clear();
	EndIf;
	
	OtherFields = New ValueTable;
	OtherFields.Columns.Add("Key", New TypeDescription("String"));
	OtherFields.Columns.Add("Value");
	
	If FoldersFromSchema = Undefined Then
		FoldersFromSchema = FoldersFromSchema();
	EndIf;
	
	For Each Folder In FoldersFromSchema Do
		If Folder.Get("id") = "COMMON_FOLDER_ID" Then
			Continue;
		EndIf;
		
		If Folder.Get("id") = Undefined
			Or Folder.Get("name") = Undefined
			Or Folder.Get("owner") = Undefined
			Or Folder.Get("type") = Undefined
			Or Folder.Get("ownerName") = Undefined
			Or Folder.Get("updated") = Undefined
			Or Folder.Get("data") = Undefined Then
			
			Raise NStr("vi = 'Bộ xử lý không hỗ trợ phiên bản sơ đồ dữ liệu';
						|ru = 'Версия схемы данных не поддерживается обработкой';
						|en = 'The ER diagram version is not supported by the data processor'; fa = 'The ER diagram version is not supported by the data processor';
						|it = 'Версия схемы данных не поддерживается обработкой';
						|pl = 'The ER diagram version is not supported by the data processor';
						|tr = 'Veri şeması sürümü veri işlemcisi tarafından desteklenmiyor'");
		EndIf;
		
		If IdsOfSubmittedObjects <> Undefined 
				And IdsOfSubmittedObjects.Get(Folder.Get("id")) = Undefined Then
			// exclusion of deleted objects
			Continue;
		EndIf; 
		
		NewRow = FoldersTable.Add();
		
		For Each Field In Folder Do
			If Field.Key = "id" Then
				NewRow.Id = Field.Value;
			ElsIf Field.Key = "name" Then
				NewRow.Name = Field.Value;
			ElsIf Field.Key = "owner" Then
				NewRow.Owner = Field.Value;
			ElsIf Field.Key = "type" Then
				NewRow.Type = Field.Value;
			ElsIf Field.Key = "ownerName" Then
				NewRow.OwnerName = Field.Value;
			ElsIf Field.Key = "updated" Then
				NewRow.Updated = Field.Value;
			ElsIf Field.Key = "data" Then
				NewRow.Data = Field.Value;
			ElsIf Field.Key = "version" Then
				NewRow.Version = Field.Value;
			ElsIf Field.Key = "links" Then
				NewRow.Links.LoadValues(Field.Value);
			Else
				NewRow.OtherFields = OtherFields;
				TableOtherFields = NewRow.OtherFields; //ValueTable
				OtherField = TableOtherFields.Add();
				OtherField.Key = Field.Key;
				If TypeOf(Field.Value) = Type("Array") Then
					ValueList = New ValueList();
					ValueList.LoadValues(Field.Value);
					OtherField.Value = ValueList;
				Else
					OtherField.Value = Field.Value;
				EndIf;
			EndIf;
		EndDo;
		
		_DataMapFolder = JSONValue(NewRow.Data);
		
		If _DataMapFolder.Get("folderIds") = Undefined Or _DataMapFolder.Get("fileIds") = Undefined Then
			Raise NStr("vi = 'Bộ xử lý không hỗ trợ phiên bản sơ đồ dữ liệu';
						|ru = 'Версия схемы данных не поддерживается обработкой';
						|en = 'The ER diagram version is not supported by the data processor'; fa = 'The ER diagram version is not supported by the data processor';
						|it = 'Версия схемы данных не поддерживается обработкой';
						|pl = 'The ER diagram version is not supported by the data processor';
						|tr = 'Veri şeması sürümü veri işlemcisi tarafından desteklenmiyor'");
		EndIf;
		
		NewRow.Data_FolderIds.LoadValues(_DataMapFolder.Get("folderIds"));
		NewRow.Data_FileIds.LoadValues(_DataMapFolder.Get("fileIds"));
	EndDo; 
	
EndProcedure

Procedure DownloadCharts(ChartsTable, IdsOfSubmittedObjects = Undefined, DiagramsFromDiagram = Undefined, ShouldClearTable = True)
	
	If ShouldClearTable Then
		ChartsTable.Clear();
	EndIf;
	
	OtherFields = New ValueTable;
	OtherFields.Columns.Add("Key", New TypeDescription("String"));
	OtherFields.Columns.Add("Value");
	
	If DiagramsFromDiagram = Undefined Then
		DiagramsFromDiagram = DiagramsFromDiagram();
	EndIf;
	
	For Each Chart In DiagramsFromDiagram Do
		If Chart.Get("originalId") <> Undefined Then // Draft
			Continue;
		EndIf;
		
		If Chart.Get("id") = Undefined
			Or Chart.Get("name") = Undefined
			Or Chart.Get("owner") = Undefined
			Or Chart.Get("type") = Undefined
			Or Chart.Get("ownerName") = Undefined
			Or Chart.Get("updated") = Undefined
			Or Chart.Get("chartType") = Undefined
			Or Chart.Get("data") = Undefined Then
			
			Raise NStr("vi = 'Bộ xử lý không hỗ trợ phiên bản sơ đồ dữ liệu';
						|ru = 'Версия схемы данных не поддерживается обработкой';
						|en = 'The ER diagram version is not supported by the data processor'; fa = 'The ER diagram version is not supported by the data processor';
						|it = 'Версия схемы данных не поддерживается обработкой';
						|pl = 'The ER diagram version is not supported by the data processor';
						|tr = 'Veri şeması sürümü veri işlemcisi tarafından desteklenmiyor'");
		EndIf;
		
		If IdsOfSubmittedObjects <> Undefined 
				And IdsOfSubmittedObjects.Get(Chart.Get("id")) = Undefined Then
			// exclusion of deleted objects
			Continue;
		EndIf;
		
		NewRow = ChartsTable.Add();
		
		For Each Field In Chart Do
			If Field.Key = "id" Then
				NewRow.Id = Field.Value;
			ElsIf Field.Key = "name" Then
				NewRow.Name = Field.Value;
			ElsIf Field.Key = "owner" Then
				NewRow.Owner = Field.Value;
			ElsIf Field.Key = "type" Then
				NewRow.Type = Field.Value;
			ElsIf Field.Key = "ownerName" Then
				NewRow.OwnerName = Field.Value;
			ElsIf Field.Key = "updated" Then
				NewRow.Updated = Field.Value;
			ElsIf Field.Key = "chartType" Then
				NewRow.ChartType = Field.Value;
			ElsIf Field.Key = "data" Then
				NewRow.Data = Field.Value;
			ElsIf Field.Key = "version" Then
				NewRow.Version = Field.Value;
			ElsIf Field.Key = "links" Then
				NewRow.Links.LoadValues(Field.Value);
			Else
				NewRow.OtherFields = OtherFields;
				TableOtherFields = NewRow.OtherFields; //ValueTable
				OtherField = TableOtherFields.Add();
				OtherField.Key = Field.Key;
				If TypeOf(Field.Value) = Type("Array") Then
					ValueList = New ValueList();
					ValueList.LoadValues(Field.Value);
					OtherField.Value = ValueList;
				Else
					OtherField.Value = Field.Value;
				EndIf;
			EndIf;
		EndDo;
			
	EndDo;
	
EndProcedure

Procedure LoadDashboards(DashboardTable, IdsOfSubmittedObjects = Undefined, DashboardsFromSchema = Undefined, ShouldClearTable = True)
	
	If ShouldClearTable Then
		DashboardTable.Clear();
	EndIf;
	
	OtherFields = New ValueTable;
	OtherFields.Columns.Add("Key", New TypeDescription("String"));
	OtherFields.Columns.Add("Value");

	If DashboardsFromSchema = Undefined Then
		DashboardsFromSchema = DashboardsFromSchema();
	EndIf;
	
	For Each Dashboard In DashboardsFromSchema Do
		If Dashboard.Get("originalId") <> Undefined Then // Draft
			Continue;
		EndIf; 
		
		If Dashboard.Get("id") = Undefined
			Or Dashboard.Get("name") = Undefined
			Or Dashboard.Get("owner") = Undefined
			Or Dashboard.Get("type") = Undefined
			Or Dashboard.Get("ownerName") = Undefined
			Or Dashboard.Get("updated") = Undefined
			Or Dashboard.Get("data") = Undefined Then
			
			Raise NStr("vi = 'Bộ xử lý không hỗ trợ phiên bản sơ đồ dữ liệu';
						|ru = 'Версия схемы данных не поддерживается обработкой';
						|en = 'The ER diagram version is not supported by the data processor'; fa = 'The ER diagram version is not supported by the data processor';
						|it = 'Версия схемы данных не поддерживается обработкой';
						|pl = 'The ER diagram version is not supported by the data processor';
						|tr = 'Veri şeması sürümü veri işlemcisi tarafından desteklenmiyor'");
		EndIf;
		
		If IdsOfSubmittedObjects <> Undefined And IdsOfSubmittedObjects.Get(Dashboard.Get("id")) = Undefined Then
			// exclusion of deleted objects
			Continue;
		EndIf;
			
		NewRow = DashboardTable.Add();
		
		For Each Field In Dashboard Do
			If Field.Key = "id" Then
				NewRow.Id = Field.Value;
			ElsIf Field.Key = "name" Then
				NewRow.Name = Field.Value;
			ElsIf Field.Key = "owner" Then
				NewRow.Owner = Field.Value;
			ElsIf Field.Key = "type" Then
				NewRow.Type = Field.Value;
			ElsIf Field.Key = "ownerName" Then
				NewRow.OwnerName = Field.Value;
			ElsIf Field.Key = "updated" Then
				NewRow.Updated = Field.Value;
			ElsIf Field.Key = "data" Then
				NewRow.Data = Field.Value;
			ElsIf Field.Key = "version" Then
				NewRow.Version = Field.Value;
			ElsIf Field.Key = "links" Then
				NewRow.Links.LoadValues(Field.Value);
			Else
				NewRow.OtherFields = OtherFields;
				TableOtherFields = NewRow.OtherFields; //ValueTable
				OtherField = TableOtherFields.Add();
				OtherField.Key = Field.Key;
				If TypeOf(Field.Value) = Type("Array") Then
					ValueList = New ValueList();
					ValueList.LoadValues(Field.Value);
					OtherField.Value = ValueList;
				Else
					OtherField.Value = Field.Value;
				EndIf;
			EndIf;
		EndDo;	
	EndDo;
	
EndProcedure  

Procedure CreateLinks(CreatingLinksByOwners, OwnersOfAnalytics, Folders)

	For Each CreatingLinkByOwner In CreatingLinksByOwners Do
		
		Panel = CreatingLinkByOwner.Key;
		ObjectsToTransfer = CreatingLinkByOwner.Value;
		
		AdditionalParameters = AdditionalParametersOfFolderFields();
		AdditionalParameters.Additional_FileIds = ObjectsToTransfer.RootFolder_FileIds;
		AdditionalParameters.Additional_FolderIds = ObjectsToTransfer.RootFolder_FolderIds;
		
		RootDirectory = FindByID(Folders, Panel.Data_RootFolderId);
		RootFolderFields = FolderFields(RootDirectory, AdditionalParameters);
		
		OwnerOfAnalytics = FindByID(OwnersOfAnalytics, Panel.Owner);
		AnalyticsUserFields = OwnerFields(OwnerOfAnalytics);
		
		JsonAnalyticsUserFields = ValueToJSON(AnalyticsUserFields);
		WriteSchema(JsonAnalyticsUserFields);
		
		JsonFolder = ValueToJSON(RootFolderFields);
		WriteSchema(JsonFolder);
		
	EndDo;
	
EndProcedure

Function AllObjectsToCreateLink(Parameters)
	
	SourcePanels = Parameters.SourcePanels;
	SelectedOwnersReceiver = Parameters.SelectedOwnersReceiver;
	Panels = Parameters.Panels;
	Charts = Parameters.Charts;
	Dashboards = Parameters.Dashboards;
	Folders = Parameters.Folders;
	
	LinesToTransfer = TreeRowsToBeProcessed(SourcePanels);
	
	LinksToOwners = New Map();
	
	For Each Panel In Panels Do
		
		If SelectedOwnersReceiver.FindByValue(Panel.OwnerName) = Undefined Then
			Continue;
		EndIf;
		
		TransferData = New Structure();
		TransferData.Insert("RootFolder_FileIds", New Array());
		TransferData.Insert("RootFolder_FolderIds", New Array());

		Transfers_1 = Transfers_1(Panel, LinesToTransfer, False, Charts, Dashboards, Folders);
		
		For Each String In LinesToTransfer Do //ValueTreeRow
			
			Transfer = Transfers_1.Get(String);
			
			If Transfer = Undefined Then
				Continue;
			EndIf;

			StringType = String.Type;
			IDRow = String.Id;
			
			If Transfer.PossibleAsLink Then
				If  String.Level() = 1 Then
					If StringType = "folder" Then
						TransferData.RootFolder_FolderIds.Add(IDRow);
					Else
						TransferData.RootFolder_FileIds.Add(IDRow);
					EndIf;
				EndIf;
			EndIf;
			
		EndDo;
		
		LinksToOwners.Insert(Panel, TransferData);
		
	EndDo;
	
	Return LinksToOwners;

EndFunction

// All objects are ready for transfer.
// 
// Parameters:
//  Parameters - Structure - Parameters:
// * FromFile - Boolean - 
// * SelectedOwnersReceiver - ValueList of String
// * ObjectID - String - 
// * SourcePanels - ValueTree 
// * Panels - ValueTable
// * Dashboards - ValueTable
// * Charts - ValueTable
// * Folders - ValueTable
// * OwnersOfAnalytics - ValueTable
// * AnalyticsObjects - ValueTable
// * DashboardsSource - ValueTable
// * SourceCharts - ValueTable
// * SourceFolders - ValueTable
// * AnalyticsObjectsSource - ValueTable
//  TreeRow - ValueTreeRow - Tree Line
//  OwnerNameOfNewPanels - String - Owner for new panels
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - ValueTableRow - transfer option.
//   * Value - Structure
Function AllObjectsToTransfer(Parameters, Val TreeRow, OwnerNameOfNewPanels)
	
	FromFile = Parameters.FromFile;
	SelectedOwnersReceiver = Parameters.SelectedOwnersReceiver;
	SourcePanels = Parameters.SourcePanels;
	Panels = Parameters.Panels;
	SourceCharts = Parameters.SourceCharts;
	DashboardsSource = Parameters.DashboardsSource;
	SourceFolders = Parameters.SourceFolders;
	AnalyticsObjectsSource = Parameters.AnalyticsObjectsSource;
	Charts = Parameters.Charts;
	Dashboards = Parameters.Dashboards;
	Folders = Parameters.Folders;
	
	SortingFolders = New ValueTable(); // to sort folders by level
	SortingFolders.Columns.Add("FolderFields");
	SortingFolders.Columns.Add("Level");
	
	LinesToTransfer = TreeRowsToBeProcessed(SourcePanels, TreeRow.Id);
	
	TransfersByOwner = New Map();
	IdsOfNewItems = New Array();
	
	For Each Panel In Panels Do
		If SelectedOwnersReceiver.FindByValue(Panel.OwnerName) = Undefined Then
			Continue;
		EndIf;
		
		Result = New Structure();
		Result.Insert("Folders", New Array());
		Result.Insert("Charts", New Array());
		Result.Insert("Dashboards", New Array());
		Result.Insert("AnalyticsObjects", New Array());
		Result.Insert("RootFolder_FileIds", New Array());
		Result.Insert("RootFolder_FolderIds", New Array());
		Result.Insert("AnalyticsUser_Links", New Array());
		Result.Insert("ThereAreThoseThatAreNotAvailableForTransfer", False);
		Result.Insert("NamesOfObjectsToReplace", New Array());
		
		Transfers_1 = Transfers_1(Panel, LinesToTransfer, FromFile, Charts, Dashboards, Folders);
		
		For Each String In LinesToTransfer Do //ValueTreeRow
			
			Transfer = Transfers_1.Get(String);
			
			If Transfer.PossibleWithSubstitution Then
				
				If Panel.OwnerName = OwnerNameOfNewPanels Then

					If String.Type = "folder" Then
						SourceObject = FindByID(SourceFolders, String.Id);
						ExistingObject = FindByID(Folders, String.Id);
						
						AdditionalParameters = AdditionalParametersOfFolderFields();
						AdditionalParameters.Additional_FileIds = SourceObject.Data_FileIds.UnloadValues();
						AdditionalParameters.Additional_FolderIds = SourceObject.Data_FolderIds.UnloadValues();
						AdditionalParameters.NewOwner = Panel.Owner;
						AdditionalParameters.NameOfNewOwner = Panel.OwnerName;
						AdditionalParameters.NewFolderName = String.Name1;
						FolderFields = FolderFields(ExistingObject, AdditionalParameters);
						
						NewRow = SortingFolders.Add();
						NewRow.FolderFields = FolderFields;
						NewRow.Level = String.Level();
					Else
						If ParentFolderCanBeMoved(String, Transfers_1) Then
							If String.Type = "chart" Then
								SourceObject = FindByID(SourceCharts, String.Id);
								SourceObjectFields = ChartFields(SourceObject,, Panel.Owner, Panel.OwnerName);
								Result.Charts.Add(SourceObjectFields);
							ElsIf String.Type = "dashboard" Then
								SourceObject = FindByID(DashboardsSource, String.Id);
								SourceObjectFields = DashboardFields(SourceObject,, Panel.Owner, Panel.OwnerName);
								Result.Dashboards.Add(SourceObjectFields);
							EndIf;
						EndIf;
					EndIf;
				
				EndIf;
			ElsIf Transfer.PossibleAsNew Then
				If String.Type = "folder" Then
					
					If Panel.OwnerName = OwnerNameOfNewPanels Then

						SourceObject = FindByID(SourceFolders, String.Id);
						
						AdditionalParameters = AdditionalParametersOfFolderFields();
						AdditionalParameters.NewOwner = Panel.Owner;
						AdditionalParameters.NameOfNewOwner = Panel.OwnerName;
						FolderFields = FolderFields(SourceObject, AdditionalParameters);
						
						NewRow = SortingFolders.Add();
						NewRow.FolderFields = FolderFields;
						NewRow.Level = String.Level();
					
					EndIf;
					
					If String.Level() = 1 Or String.Id = TreeRow.Id Then
						Result.RootFolder_FolderIds.Add(String.Id);
					EndIf;
					
					IdsOfNewItems.Add(String.Id);
				Else
					If ParentFolderCanBeMoved(String, Transfers_1) Then
						
						If Panel.OwnerName = OwnerNameOfNewPanels Then

							If String.Type = "chart" Then
								SourceObject = FindByID(SourceCharts, String.Id);
								SourceObjectFields = ChartFields(SourceObject,, Panel.Owner, Panel.OwnerName);
								Result.Charts.Add(SourceObjectFields);
							ElsIf String.Type = "dashboard" Then
								SourceObject = FindByID(DashboardsSource, String.Id);
								SourceObjectFields = DashboardFields(SourceObject,, Panel.Owner, Panel.OwnerName);
								Result.Dashboards.Add(SourceObjectFields);
							EndIf; 
							
							For Each Item In SourceObjectFields["links"] Do
								SourceAnalyticsObject = FindByID(AnalyticsObjectsSource, Item);
								If SourceAnalyticsObject = Undefined Then
									Continue;
								EndIf;
								
								If Result.AnalyticsUser_Links.Find(Item) = Undefined Then
									Result.AnalyticsUser_Links.Add(Item);
								EndIf;
								
								FieldsOfAnalyticsObject = FieldsOfAnalyticsObject(SourceAnalyticsObject, , Panel.Owner, Panel.OwnerName);
								
								RelatedObjectReferences = FieldsOfAnalyticsObject["links"];
								If RelatedObjectReferences <> Undefined Then
									For Each Item2 In RelatedObjectReferences Do
										RelatedSourceObject = FindByID(AnalyticsObjectsSource, Item2);
										If RelatedSourceObject = Undefined Then
											Continue;
										EndIf;
										FieldsOfLinkedObject = FieldsOfAnalyticsObject(RelatedSourceObject, , Panel.Owner, Panel.OwnerName);
										Result.AnalyticsObjects.Add(FieldsOfLinkedObject);
									EndDo;
								EndIf;
								
								Result.AnalyticsObjects.Add(FieldsOfAnalyticsObject);
							EndDo;
						
						EndIf;
						
						If String.Level() = 1 Then
							Result.RootFolder_FileIds.Add(String.Id);
						EndIf;
						
						IdsOfNewItems.Add(String.Id);
					EndIf;
				EndIf;
			EndIf;
			
		EndDo;
		
		If FromFile And Panel.OwnerName = OwnerNameOfNewPanels Then 
			
			SortingFolders.Sort("Level Desc");
			Result.Folders = SortingFolders.UnloadColumn("FolderFields");
			
			For Each Folder In Result.Folders Do 
				_DataFolder = JSONValue(Folder.Get("data"));
				
				Folder_FileIds = _DataFolder.Get("fileIds");
				Folder_FolderIds = _DataFolder.Get("folderIds");
				_LinksFolder = Folder.Get("links");
				
				FileIds_TOException = New Array();
				For Each ID In Folder_FileIds Do
					If IdsOfNewItems.Find(ID) = Undefined And Panel.IdsOfSubmittedObjects.FindByValue(ID) = Undefined Then
						FileIds_TOException.Add(ID);
					EndIf;
				EndDo;
				FolderIds_ToException = New Array();
				For Each ID In Folder_FolderIds Do
					If IdsOfNewItems.Find(ID) = Undefined And Panel.IdsOfSubmittedObjects.FindByValue(ID) = Undefined Then
						FolderIds_ToException.Add(ID);
					EndIf;
				EndDo;
				
				For Each ID In FileIds_TOException Do 
					Folder_FileIds.Delete(Folder_FileIds.Find(ID));
					_LinksFolder.Delete(_LinksFolder.Find(ID));
				EndDo;
				For Each ID In FolderIds_ToException Do 
					Folder_FolderIds.Delete(Folder_FolderIds.Find(ID));
					_LinksFolder.Delete(_LinksFolder.Find(ID));
				EndDo;
				
				Folder.Insert("data", ValueToJSON(_DataFolder));
			EndDo;
		EndIf;
		
		TransfersByOwner.Insert(Panel, Result);
		
	EndDo;

	Return TransfersByOwner;
	
EndFunction

Function TransferAvailability(ReceiverPanel, SourceObject, FromFile, Charts, Dashboards, Folders)
	
	Result = New Structure();
	Result.Insert("PossibleAsLink", False);
	Result.Insert("PossibleAsNew", False);
	Result.Insert("PossibleWithSubstitution", False);
	
	If FromFile Then
		
		If SourceObject.Type = "chart" Then
			SearchTable = Charts;
		ElsIf SourceObject.Type = "dashboard" Then
			SearchTable = Dashboards;
		ElsIf SourceObject.Type = "folder" Then
			SearchTable = Folders;
		EndIf;
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Id", SourceObject.Id);
		TheStructureOfTheSearch.Insert("Owner", ReceiverPanel.Owner);
		SearchResult = SearchTable.FindRows(TheStructureOfTheSearch);
		If SearchResult.Count() Then
			If ReceiverPanel.IdsOfSubmittedObjects.FindByValue(SourceObject.Id) <> Undefined Then
				Result.Insert("PossibleWithSubstitution", True);
			Else
				Result.Insert("PossibleAsNew", True);
			EndIf;
		Else
			Result.Insert("PossibleAsNew", True);
		EndIf;

	Else
		
		If ReceiverPanel.IdsOfSubmittedObjects.FindByValue(SourceObject.Id) <> Undefined Then
			Result.Insert("PossibleWithSubstitution", True);
		Else
			Result.Insert("PossibleAsLink", True);
			Result.Insert("PossibleAsNew", True);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure TransferObjectsFromFile(
	TransfersByOwner,
	OwnersOfAnalytics,
	AnalyticsObjectsSource,
	Folders,
	AdditionalSources,
	PanelSettingsIds,
	ServerAddress,
	FromFile)
	
	For Each TransferByOwner In TransfersByOwner Do
		
		Panel = TransferByOwner.Key;
		ObjectsToTransfer = TransferByOwner.Value;
		
		For Each DimensionObject In ObjectsToTransfer.AnalyticsObjects Do
			RecordRelatedAdditionalSources(DimensionObject["id"], AdditionalSources, PanelSettingsIds,
				ServerAddress, FromFile);
			JsonSchema = ValueToJSON(DimensionObject);
			WriteSchema(JsonSchema)
		EndDo;
		For Each Chart In ObjectsToTransfer.Charts Do
			RecordRelatedAdditionalSources(Chart["id"], AdditionalSources, PanelSettingsIds,
				ServerAddress, FromFile);
			JsonSchema = ValueToJSON(Chart);
			WriteSchema(JsonSchema);
		EndDo;
		For Each Dashboard In ObjectsToTransfer.Dashboards Do
			RecordRelatedAdditionalSources(Dashboard["id"], AdditionalSources, PanelSettingsIds,
				ServerAddress, FromFile);
			JsonSchema = ValueToJSON(Dashboard);
			WriteSchema(JsonSchema);
		EndDo;
		For Each Folder In ObjectsToTransfer.Folders Do
			JsonSchema = ValueToJSON(Folder);
			WriteSchema(JsonSchema)
		EndDo;
			
		RootDirectory = FindByID(Folders, Panel.Data_RootFolderId);
		
		AdditionalParameters = AdditionalParametersOfFolderFields();
		AdditionalParameters.Additional_FileIds = ObjectsToTransfer.RootFolder_FileIds;
		AdditionalParameters.Additional_FolderIds = ObjectsToTransfer.RootFolder_FolderIds;
		RootFolderFields = FolderFields(RootDirectory, AdditionalParameters);
		
		OwnerOfAnalytics = FindByID(OwnersOfAnalytics, Panel.Owner);
		AnalyticsUserFields = OwnerFields(OwnerOfAnalytics);
		
		For Each Item In ObjectsToTransfer.AnalyticsUser_Links Do
			If AnalyticsUserFields["links"].Find(Item) = Undefined Then
				AnalyticsUserFields["links"].Add(Item);
			EndIf;
			
			DimensionObject = FindByID(AnalyticsObjectsSource, Item);
			
			If DimensionObject = Undefined Then
				Continue;
			EndIf;
			
			User_DataMap = JSONValue(AnalyticsUserFields["data"]);
			ObjectTypeName = DimensionObject.Type;
			If ObjectTypeName = "colorScheme" Or ObjectTypeName = "globalMacro" Or ObjectTypeName = "gradient" 
				Or ObjectTypeName = "markerMap" Or ObjectTypeName = "areasMapping" Then
					
				NameOfIdsField = ObjectTypeName + "Ids";
				FoundUser_DataMap = User_DataMap.Get(NameOfIdsField); //ValueList
				If FoundUser_DataMap <> Undefined Then
					FoundUser_DataMap.Add(Item)
				Else
					IDArray = New Array();
					IDArray.Add(Item);
					User_DataMap.Insert(NameOfIdsField, IDArray);
				EndIf;
			EndIf;
			AnalyticsUserFields["data"] = ValueToJSON(User_DataMap);
			
		EndDo;
		
		JsonAnalyticsUserFields = ValueToJSON(AnalyticsUserFields);
		WriteSchema(JsonAnalyticsUserFields);
		
		JsonFolder = ValueToJSON(RootFolderFields);
		WriteSchema(JsonFolder);
		
	EndDo;
	
EndProcedure

Function PanelFields(Panel, IdsOfAdditionalObjects = Undefined)
	
	Fields = New Map();
	
	_LinksPanel = Panel.Links.UnloadValues();
	If IdsOfAdditionalObjects <> Undefined Then
		For Each ID In IdsOfAdditionalObjects Do
			_LinksPanel.Add(ID);
		EndDo;
	EndIf;
	
	Desktop_Data = New Map();
	Desktop_Data.Insert("rootFolderId", Panel.Data_RootFolderId);
	
	Fields.Insert("type", "desktop");
	Fields.Insert("id", Panel.Id);
	Fields.Insert("owner", Panel.Owner);
	Fields.Insert("ownerName", Panel.OwnerName);
	Fields.Insert("updated", Panel.Updated);
	
	If _LinksPanel.Count() <> 0 Then
		Fields.Insert("links", _LinksPanel); 
	EndIf;
	
	Fields.Insert("data", ValueToJSON(Desktop_Data));
	If Panel.Version > 0 Then
		Fields.Insert("version", Panel.Version);
	EndIf; 
	
	For Each Field In Panel.OtherFields Do
		Fields.Insert(Field.Key, Field.Value);
	EndDo;
	
	Return Fields;
	
EndFunction

Function AdditionalParametersOfFolderFields()
	
	Structure = New Structure;
	Structure.Insert("Additional_FileIds", Undefined);
	Structure.Insert("Additional_FolderIds", Undefined);
	Structure.Insert("NewID", Undefined);
	Structure.Insert("NewFolderName", Undefined);
	Structure.Insert("NewOwner", Undefined);
	Structure.Insert("NameOfNewOwner", Undefined);
	
	Return Structure;
	
EndFunction

Function FolderFields(Folder, AdditionalParameters = Undefined)
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AdditionalParametersOfFolderFields();
	EndIf;
	
	Additional_FileIds = AdditionalParameters.Additional_FileIds;
	Additional_FolderIds = AdditionalParameters.Additional_FolderIds;
	NewID = AdditionalParameters.NewID;
	NewFolderName = AdditionalParameters.NewFolderName;
	NewOwner = AdditionalParameters.NewOwner;
	NameOfNewOwner = AdditionalParameters.NameOfNewOwner;
	
	Folder_Id = ?(NewID = Undefined, Folder.Id, NewID);
	Folder_Name = ?(NewFolderName = Undefined, Folder.Name, NewFolderName);
	Folder_Owner = ?(NewOwner = Undefined, Folder.Owner, NewOwner);
	Folder_OwnerName = ?(NameOfNewOwner = Undefined, Folder.OwnerName, NameOfNewOwner);
	
	FolderFields = New Map();
	
	_LinksFolder = Folder.Links.UnloadValues(); //ValueList
	
	Folder_FileIds = Folder.Data_FileIds.UnloadValues();
	If Additional_FileIds <> Undefined Then
		CommonClientServer.SupplementArray(Folder_FileIds, Additional_FileIds, True);
		CommonClientServer.SupplementArray(_LinksFolder, Additional_FileIds, True);
	EndIf;
	
	Folder_FolderIds = Folder.Data_FolderIds.UnloadValues();
	If Additional_FolderIds <> Undefined Then
		CommonClientServer.SupplementArray(Folder_FolderIds, Additional_FolderIds, True);
		CommonClientServer.SupplementArray(_LinksFolder, Additional_FolderIds, True);
	EndIf;
	
	_DataFolder = New Map();
	_DataFolder.Insert("fileIds", Folder_FileIds);
	_DataFolder.Insert("folderIds", Folder_FolderIds);
	
	FolderFields.Insert("type", "folder");
	FolderFields.Insert("id", Folder_Id);
	FolderFields.Insert("name", Folder_Name);
	FolderFields.Insert("ownerName",Folder_OwnerName);
	FolderFields.Insert("owner", Folder_Owner);
	FolderFields.Insert("updated", Folder.Updated);
	
	FolderFields.Insert("links", _LinksFolder);
	
	FolderFields.Insert("data", ValueToJSON(_DataFolder));
	If Folder.Version > 0 Then
		FolderFields.Insert("version", Folder.Version);
	EndIf;
	
	For Each Field In Folder.OtherFields Do
		FolderFields.Insert(Field.Key, Field.Value);
	EndDo;
	
	Return FolderFields;
	
EndFunction

Function ChartFields(Chart, NewID = Undefined, NewOwner = Undefined, NameOfNewOwner = Undefined)
	
	Diagram_Id = ?(NewID = Undefined, Chart.Id, NewID); 
	_ownerDiagram = ?(NewOwner = Undefined, Chart.Owner, NewOwner);
	Diagram_OwnerName = ?(NameOfNewOwner = Undefined, Chart.OwnerName, NameOfNewOwner);
	
	ChartFields = New Map();
	
	ChartFields.Insert("type", "chart");
	ChartFields.Insert("id", Diagram_Id);
	ChartFields.Insert("name", Chart.Name);
	ChartFields.Insert("chartType", Chart.ChartType);
	ChartFields.Insert("owner", _ownerDiagram);
	ChartFields.Insert("ownerName", Diagram_OwnerName); 
	ChartFields.Insert("data", Chart.Data);
	ChartFields.Insert("updated", Chart.Updated);
	If Chart.Version > 0 Then
		ChartFields.Insert("version", Chart.Version);
	EndIf;
	
	ChartFields.Insert("links", Chart.Links.UnloadValues());
	
	For Each Field In Chart.OtherFields Do
		If TypeOf(Field.Value) = Type("ValueList") Then
			ChartFields.Insert(Field.Key, Field.Value.UnloadValues());
		Else
			ChartFields.Insert(Field.Key, Field.Value);
		EndIf;
	EndDo;
	
	Return ChartFields;
	
EndFunction

Function DashboardFields(Dashboard, NewID = Undefined, NewOwner = Undefined, NameOfNewOwner = Undefined)
	
	Dashboard_Id = ?(NewID = Undefined, Dashboard.Id, NewID); 
	Dashboard_Owner = ?(NewOwner = Undefined, Dashboard.Owner, NewOwner);
	Dashboard_OwnerName = ?(NameOfNewOwner = Undefined, Dashboard.OwnerName, NameOfNewOwner);
	
	DashboardFields = New Map();
	
	DashboardFields.Insert("type", "dashboard");
	DashboardFields.Insert("id", Dashboard_Id);
	DashboardFields.Insert("name", Dashboard.Name);
	DashboardFields.Insert("owner", Dashboard_Owner); 
	DashboardFields.Insert("ownerName", Dashboard_OwnerName);
	DashboardFields.Insert("data", Dashboard.Data);
	
	DashboardFields.Insert("links", Dashboard.Links.UnloadValues());
	
	DashboardFields.Insert("updated", Dashboard.Updated);
	If Dashboard.Version > 0 Then
		DashboardFields.Insert("version", Dashboard.Version);
	EndIf;
	
	For Each Field In Dashboard.OtherFields Do
		DashboardFields.Insert(Field.Key, Field.Value);
	EndDo;
	
	Return DashboardFields; 
	
EndFunction

Function FieldsOfAnalyticsObject(DimensionObject, NewID = Undefined, NewOwner = Undefined, NameOfNewOwner = Undefined)
	
	FieldsOfAnalyticsObject = New Map();
	
	FieldsOfAnalyticsObject.Insert("type", DimensionObject.Type);
	FieldsOfAnalyticsObject.Insert("id", ?(NewID = Undefined, DimensionObject.Id, NewID));
	
	If Not IsBlankString(DimensionObject.Owner) Then
		FieldsOfAnalyticsObject.Insert("owner", ?(NewOwner = Undefined, DimensionObject.Owner, NewOwner));
	EndIf;
		
	If Not IsBlankString(DimensionObject.OwnerName) Then
		FieldsOfAnalyticsObject.Insert("ownerName", ?(NameOfNewOwner = Undefined, DimensionObject.OwnerName, NameOfNewOwner));
	EndIf;
	
	If Not IsBlankString(DimensionObject.Name) Then
		FieldsOfAnalyticsObject.Insert("name", DimensionObject.Name);
	EndIf;
	
	If Not IsBlankString(DimensionObject.Data) Then
		FieldsOfAnalyticsObject.Insert("data", DimensionObject.Data);
	EndIf;
	
	If DimensionObject.Links.Count() <> 0 Then
		FieldsOfAnalyticsObject.Insert("links", DimensionObject.Links.UnloadValues());
	EndIf;

	If Not IsBlankString(DimensionObject.Updated) Then
		FieldsOfAnalyticsObject.Insert("updated", DimensionObject.Updated);
	EndIf;
	
	If DimensionObject.Version > 0 Then
		FieldsOfAnalyticsObject.Insert("version", DimensionObject.Version);
	EndIf;
	
	For Each Field In DimensionObject.OtherFields Do
		FieldsOfAnalyticsObject.Insert(Field.Key, Field.Value);
	EndDo;
	
	Return FieldsOfAnalyticsObject;
	
EndFunction

Function OwnerFields(Owner)
	
	Fields = New Map();
	Fields.Insert("owner", Owner.Owner);
	Fields.Insert("data", Owner.Data);
	Fields.Insert("ownerName", Owner.OwnerName);
	
	If Owner.Links.Count() <> 0 Then
		Fields.Insert("links", Owner.Links.UnloadValues());
	EndIf;
	
	Fields.Insert("id", Owner.Id);
	Fields.Insert("type", Owner.Type);
	Fields.Insert("updated", Owner.Updated);
	If Owner.Version > 0 Then
		Fields.Insert("version", Owner.Version);
	EndIf;
	
	For Each Field In Owner.OtherFields Do
		Fields.Insert(Field.Key, Field.Value);
	EndDo;
	
	Return Fields;
	
EndFunction

Function NewID1()
	
	Return StrReplace(String(New UUID()), "-", "");
	
EndFunction

// Add a chart to a chart table.
// 
// Parameters:
//  ChartsTable - ValueTable - Chart Table
//  Chart - Map of String - Chart
Procedure AddChartToChartTable(ChartsTable, Chart)
	
	NewRow = ChartsTable.Add();
	
	OtherFields = New ValueTable;
	OtherFields.Columns.Add("Key", New TypeDescription("String"));
	OtherFields.Columns.Add("Value");
	
	For Each Field In Chart Do
		If Field.Key = "id" Then
			NewRow.Id = Field.Value;
		ElsIf Field.Key = "name" Then
			NewRow.Name = Field.Value;
		ElsIf Field.Key = "owner" Then
			NewRow.Owner = Field.Value;
		ElsIf Field.Key = "type" Then
			NewRow.Type = Field.Value;
		ElsIf Field.Key = "ownerName" Then
			NewRow.OwnerName = Field.Value;
		ElsIf Field.Key = "updated" Then
			NewRow.Updated = Field.Value;
		ElsIf Field.Key = "chartType" Then
			NewRow.ChartType = Field.Value;
		ElsIf Field.Key = "data" Then
			NewRow.Data = Field.Value;
		ElsIf Field.Key = "version" Then
			NewRow.Version = Field.Value;
		ElsIf Field.Key = "links" Then
			NewRow.Links.LoadValues(Field.Value);
		Else
			NewRow.OtherFields = OtherFields;
			TableOtherFields = NewRow.OtherFields; //ValueTable
			OtherField = TableOtherFields.Add();
			OtherField.Key = Field.Key;
			If TypeOf(Field.Value) = Type("Array") Then
				ValueList = New ValueList();
				ValueList.LoadValues(Field.Value);
				OtherField.Value = ValueList;
			Else
				OtherField.Value = Field.Value;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Add a dashboard to the dashboard table.
// 
// Parameters:
//  DashboardTable - ValueTable - Dashboard Table
//  Dashboard - Map of String - Dashboard
Procedure AddDashboardToDashboardTable(DashboardTable, Dashboard)
	
	NewRow = DashboardTable.Add();
	
	OtherFields = New ValueTable;
	OtherFields.Columns.Add("Key", New TypeDescription("String"));
	OtherFields.Columns.Add("Value");
	
	For Each Field In Dashboard Do
		If Field.Key = "id" Then
			NewRow.Id = Field.Value;
		ElsIf Field.Key = "name" Then
			NewRow.Name = Field.Value;
		ElsIf Field.Key = "owner" Then
			NewRow.Owner = Field.Value;
		ElsIf Field.Key = "type" Then
			NewRow.Type = Field.Value;
		ElsIf Field.Key = "ownerName" Then
			NewRow.OwnerName = Field.Value;
		ElsIf Field.Key = "updated" Then
			NewRow.Updated = Field.Value;
		ElsIf Field.Key = "data" Then
			NewRow.Data = Field.Value;
		ElsIf Field.Key = "version" Then
			NewRow.Version = Field.Value;
		ElsIf Field.Key = "links" Then
			NewRow.Links.LoadValues(Field.Value);
		Else
			NewRow.OtherFields = OtherFields;
			TableOtherFields = NewRow.OtherFields; //ValueTable
			OtherField = TableOtherFields.Add();
			OtherField.Key = Field.Key;
			If TypeOf(Field.Value) = Type("Array") Then
				ValueList = New ValueList();
				ValueList.LoadValues(Field.Value);
				OtherField.Value = ValueList;
			Else
				OtherField.Value = Field.Value;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure CreateAndConnectToPanel(Panel, SelectedObject, Parameters, Id = Undefined)

	ThisIsRecursiveCall = False;
	If Id = Undefined Then
		ObjectID = Parameters.ObjectID;
	Else
		ObjectID = Id;
		ThisIsRecursiveCall = True;
	EndIf;
	FromFile = Parameters.FromFile;
	OwnersOfAnalytics = Parameters.OwnersOfAnalytics;
	SourceCharts = Parameters.SourceCharts;
	DashboardsSource = Parameters.DashboardsSource;
	AnalyticsObjectsSource = Parameters.AnalyticsObjectsSource;
	Folders = Parameters.Folders;
	Charts = Parameters.Charts;
	Dashboards = Parameters.Dashboards;
	SourcePanels = Parameters.SourcePanels;
	IdsToOverwrite = Parameters.IdsToOverwrite;
	
	If SelectedObject.Type = "chart" Then
		SourceObject = FindByID(SourceCharts, ObjectID);
	ElsIf SelectedObject.Type = "dashboard" Then
		SourceObject = FindByID(DashboardsSource, ObjectID);
	EndIf;
	
	SearchIdentifier = IdsToOverwrite.FindByValue(ObjectID);
	If SearchIdentifier <> Undefined Then
		IdOfNewObject = SearchIdentifier.Value;
	ElsIf FromFile Then
		IdOfNewObject = ObjectID;
	Else
		IdOfNewObject = NewID1();
	EndIf;
	
	If SourceObject.Type = "chart" Then
		FieldsOfNewObject = ChartFields(SourceObject, IdOfNewObject, Panel.Owner, Panel.OwnerName);
		AddChartToChartTable(Charts, FieldsOfNewObject);
	ElsIf SourceObject.Type = "dashboard" Then
		FieldsOfNewObject = DashboardFields(SourceObject, IdOfNewObject, Panel.Owner, Panel.OwnerName);
		If FromFile Then
			For Each LinkField In FieldsOfNewObject["links"] Do
				ChartInDashboard = FindByID(SourceCharts, LinkField);
				
				If ChartInDashboard = Undefined Then
					Continue;
				EndIf;
				
				NestedObject = SourcePanels.Rows.Find(LinkField, "Id", True);
				CreateAndConnectToPanel(Panel, NestedObject, Parameters, ChartInDashboard.Id)
			EndDo;
		EndIf;
		AddDashboardToDashboardTable(Dashboards, FieldsOfNewObject);
	EndIf;
	
	OwnerOfAnalytics = FindByID(OwnersOfAnalytics, Panel.Owner);
	AnalyticsUserFields = OwnerFields(OwnerOfAnalytics);
	
	If AnalyticsUserFields["links"].Find(IdOfNewObject) = Undefined Then
		AnalyticsUserFields["links"].Add(IdOfNewObject);
		CommonClientServer.SupplementArray(
			OwnerOfAnalytics.links,
			CommonClientServer.ValueInArray(IdOfNewObject),
			True);
	EndIf;
	
	For Each Item In FieldsOfNewObject["links"] Do
		SourceAnalyticsObject = FindByID(AnalyticsObjectsSource, Item);
		
		If SourceAnalyticsObject = Undefined Then
			Continue;
		EndIf;
		
		SearchIdentifier = IdsToOverwrite.FindByValue(Item);
		If SearchIdentifier <> Undefined Then
			IdOfNewAnalyticsObject = SearchIdentifier.Value;
		Else
			IdOfNewAnalyticsObject = Item;
		EndIf;
		
		If AnalyticsUserFields["links"].Find(IdOfNewAnalyticsObject) = Undefined Then
			AnalyticsUserFields["links"].Add(IdOfNewAnalyticsObject);
			CommonClientServer.SupplementArray(
				OwnerOfAnalytics.links,
				CommonClientServer.ValueInArray(IdOfNewAnalyticsObject),
				True);
		EndIf;
		
		User_DataMap = JSONValue(AnalyticsUserFields["data"]);
		ObjectTypeName = SourceAnalyticsObject.Type;
		If ObjectTypeName = "colorScheme" Or ObjectTypeName = "globalMacro" Or ObjectTypeName = "gradient" 
			Or ObjectTypeName = "markerMap" Or ObjectTypeName = "areasMapping" Then
			
			NameOfIdsField = ObjectTypeName + "Ids";
			UserIdFields = User_DataMap.Get(NameOfIdsField); //ValueList
			If UserIdFields <> Undefined Then
				UserIdFields.Add(IdOfNewAnalyticsObject)
			Else
				IDArray = New Array();
				IDArray.Add(IdOfNewAnalyticsObject);
				User_DataMap.Insert(NameOfIdsField, IDArray);
			EndIf;
		EndIf;
		AnalyticsUserFields["data"] = ValueToJSON(User_DataMap);
		OwnerOfAnalytics.Data = AnalyticsUserFields["data"];
		
		FieldsOfAnalyticsObject = FieldsOfAnalyticsObject(SourceAnalyticsObject, IdOfNewAnalyticsObject, Panel.Owner, Panel.OwnerName);
		
		RelatedObjectReferences = FieldsOfAnalyticsObject["links"];
		If RelatedObjectReferences <> Undefined Then
			For Each Item2 In RelatedObjectReferences Do
				LinkedObject = FindByID(AnalyticsObjectsSource, Item2);
				If LinkedObject = Undefined Then
					Continue;
				EndIf;
				FieldsOfLinkedObject = FieldsOfAnalyticsObject(LinkedObject, , Panel.Owner, Panel.OwnerName);
				FieldsOfLinkedJsonObject = ValueToJSON(FieldsOfLinkedObject);
				WriteSchema(FieldsOfLinkedJsonObject);
			EndDo;
		EndIf;
		
		FieldsOfJsonAnalyticsObject = ValueToJSON(FieldsOfAnalyticsObject);
		WriteSchema(FieldsOfJsonAnalyticsObject);
	EndDo;
	
	IdsOfNewObject = New Array();
	IdsOfNewObject.Add(IdOfNewObject);
	If Not ThisIsRecursiveCall Then
		RootDirectory = FindByID(Folders, Panel.Data_RootFolderId);
	EndIf;
	
	AdditionalParameters = AdditionalParametersOfFolderFields();
	AdditionalParameters.Additional_FileIds = IdsOfNewObject;
	If Not ThisIsRecursiveCall Then
		RootFolderFields = FolderFields(RootDirectory, AdditionalParameters);
	EndIf;
	
	FieldsOfNewJsonObject = ValueToJSON(FieldsOfNewObject);
	JsonRootFolderFields = ValueToJSON(RootFolderFields);
	JsonAnalyticsUserFields = ValueToJSON(AnalyticsUserFields);
	
	WriteSchema(FieldsOfNewJsonObject);
	If Not ThisIsRecursiveCall Then
		WriteSchema(JsonRootFolderFields);
	EndIf;
	WriteSchema(JsonAnalyticsUserFields);
	
	If FromFile And ThisIsRecursiveCall Then
		
		For Each SourceFolder In Parameters.SourceFolders Do
			If SourceFolder.Data_FileIds.Count() = 0 Then
				Continue;
			EndIf;
			
			Data_FileIds = SourceFolder.Data_FileIds.UnloadValues();
			ObjectBelongsToSourceFolder = Data_FileIds.Find(IdOfNewObject) <> Undefined;
			If ObjectBelongsToSourceFolder Then
				CopySourceFolder(SourceFolder.Id, Parameters, Panel, IdOfNewObject);
			EndIf;
		EndDo;
		
	EndIf;
EndProcedure

Procedure ConnectToPanel(Panel, SelectedObject, Parameters)

	OwnersOfAnalytics = Parameters.OwnersOfAnalytics;
	Charts = Parameters.Charts;
	Dashboards = Parameters.Dashboards;
	Folders = Parameters.Folders;
	
	RootDirectory = FindByID(Folders, Panel.Data_RootFolderId);
	
	IdsOfSelectedObject = New Array();
	IdsOfSelectedObject.Add(SelectedObject.Id);
	
	If SelectedObject.Type = "folder" Then
		AdditionalParameters = AdditionalParametersOfFolderFields();
		AdditionalParameters.Additional_FolderIds = IdsOfSelectedObject;
		RootFolderFields = FolderFields(RootDirectory, AdditionalParameters);
	Else
		AdditionalParameters = AdditionalParametersOfFolderFields();
		AdditionalParameters.Additional_FileIds = IdsOfSelectedObject;
		RootFolderFields = FolderFields(RootDirectory, AdditionalParameters);
	EndIf;
	
	If SelectedObject.Type = "chart" Then
		SourceObject = FindByID(Charts, SelectedObject.Id);
	ElsIf SelectedObject.Type = "dashboard" Then
		SourceObject = FindByID(Dashboards, SelectedObject.Id);
	ElsIf SelectedObject.Type = "folder" Then
		SourceObject = FindByID(Folders, SelectedObject.Id);
	EndIf;
	
	OwnerOfAnalytics = FindByID(OwnersOfAnalytics, Panel.Owner);
	AnalyticsUserFields = OwnerFields(OwnerOfAnalytics);
	
	If AnalyticsUserFields["links"].Find(SelectedObject.Id) = Undefined Then
		AnalyticsUserFields["links"].Add(SelectedObject.Id);
	EndIf;
	
	For Each Item In SourceObject.Links Do
		If AnalyticsUserFields["links"].Find(Item) = Undefined Then
			AnalyticsUserFields["links"].Add(Item.Value);
		EndIf;
	EndDo;
	
	JsonRootFolderFields = ValueToJSON(RootFolderFields);
	JsonAnalyticsUserFields = ValueToJSON(AnalyticsUserFields);
	
	WriteSchema(JsonRootFolderFields);
	WriteSchema(JsonAnalyticsUserFields);
	
EndProcedure

// Delete from the panel.
// 
// Parameters:
//  Panel - ValueTableRow - Panel
//  SelectedObject - ValueTreeRow - Selected object
//  Parameters - See DataProcessors.Manage1CAnalyticsPanels.PanelRemovalOptions
Procedure DeleteFromPanel(Panel, SelectedObject, Parameters)

	OwnersOfAnalytics = Parameters.OwnersOfAnalytics;
	Charts = Parameters.Charts;
	Dashboards = Parameters.Dashboards;
	Folders = Parameters.Folders;
	
	RootDirectory = FindByID(Folders, Panel.Data_RootFolderId);

	If SelectedObject.Type = "folder" Then
		NameOfSearchCollection = "Data_FolderIds";
	Else
		NameOfSearchCollection = "Data_FileIds";
	EndIf;
	
	ProcessListOfPanels(RootDirectory, NameOfSearchCollection, Folders, SelectedObject.Id);
	
	RootFolderFields = FolderFields(RootDirectory);
	
	If SelectedObject.Type = "chart" Then
		SourceObject = FindByID(Charts, SelectedObject.Id);
	ElsIf SelectedObject.Type = "dashboard" Then
		SourceObject = FindByID(Dashboards, SelectedObject.Id);
	ElsIf SelectedObject.Type = "folder" Then
		SourceObject = FindByID(Folders, SelectedObject.Id);
	EndIf;
	
	OwnerOfAnalytics = FindByID(OwnersOfAnalytics, Panel.Owner);
	AnalyticsUserFields = OwnerFields(OwnerOfAnalytics);
	
	FoundItem = AnalyticsUserFields["links"].Find(SelectedObject.Id);
	If FoundItem <> Undefined Then
		AnalyticsUserFields["links"].Delete(FoundItem);
	EndIf;
	
	For Each Item In SourceObject.Links Do
		FoundItem = AnalyticsUserFields["links"].Find(Item);
		If FoundItem <> Undefined Then
			AnalyticsUserFields["links"].Delete(FoundItem);
		EndIf;
	EndDo;
	
	JsonRootFolderFields = ValueToJSON(RootFolderFields);
	JsonAnalyticsUserFields = ValueToJSON(AnalyticsUserFields);
	
	WriteSchema(JsonRootFolderFields);
	WriteSchema(JsonAnalyticsUserFields);
	
EndProcedure

Procedure ProcessListOfPanels(Folder, NameOfSearchCollection, Folders, ObjectIdentifier, Deleted = False)
	
	SearchResultsList = Folder[NameOfSearchCollection];
	
	FoundItem = SearchResultsList.FindByValue(ObjectIdentifier);
	If FoundItem <> Undefined Then
		SearchResultsList.Delete(FoundItem);
		Deleted = True;
		Return;
	Else
		For Each Subfolder_Id In Folder.Data_FolderIds Do
			If Deleted Then
				Return;
			EndIf;
			
			Subfolder = FindByID(Folders, Subfolder_Id.Value);
			
			If Folder.Owner <> Subfolder.Owner Then
				Return;
			EndIf;
			
			Folder = Subfolder;
			ProcessListOfPanels(Folder, NameOfSearchCollection, Folders, ObjectIdentifier, Deleted);
		EndDo;
	EndIf;
	
EndProcedure

Procedure CopySourceFolder(IdOfSourceFolder, Parameters, Panel, FileID = Undefined, FolderID_ = Undefined)
	
	SourceFolders = Parameters.SourceFolders;
	Folders = Parameters.Folders;
	
	New_Folder = FindByID(Folders, IdOfSourceFolder);
	If New_Folder = Undefined Then
		New_Folder = Folders.Add();
		
		SourceFolder = FindByID(SourceFolders, IdOfSourceFolder);
		PropertyExceptions = "Data, Data_FileIds, Data_FolderIds, Links";
		FillPropertyValues(New_Folder, SourceFolder, , PropertyExceptions);
	EndIf;
	
	AdditionalParameters = AdditionalParametersOfFolderFields();
	AdditionalParameters.NewOwner = Panel.Owner;
	AdditionalParameters.NameOfNewOwner = Panel.OwnerName;
	
	If FileID <> Undefined Then
		IdOfFileInArray = CommonClientServer.ValueInArray(FileID);
		AdditionalParameters.Additional_FileIds = IdOfFileInArray;
		AddUniqueElementToList(New_Folder.Data_FileIds, FileID);
	EndIf;
	If FolderID_ <> Undefined Then
		IdOfFolderInArray = CommonClientServer.ValueInArray(FolderID_);
		AdditionalParameters.Additional_FolderIds = IdOfFolderInArray;
		AddUniqueElementToList(New_Folder.Data_FolderIds, FolderID_);
	EndIf;
	
	FieldsOfNewFolder = FolderFields(New_Folder, AdditionalParameters);
	FieldsOfNewJsonFolder = ValueToJSON(FieldsOfNewFolder);
	WriteSchema(FieldsOfNewJsonFolder);
	
	New_Folder.Data = FieldsOfNewFolder["data"];
	New_Folder.Links.LoadValues(FieldsOfNewFolder["links"]);
	New_Folder.Owner = FieldsOfNewFolder["owner"];
	New_Folder.OwnerName = FieldsOfNewFolder["ownerName"];
	
	For Each SourceFolder In SourceFolders Do
		If SourceFolder.Data_FolderIds.Count() = 0 Then
			Continue;
		EndIf;
		
		Data_FolderIds = SourceFolder.Data_FolderIds.UnloadValues();
		If Data_FolderIds.Find(IdOfSourceFolder) <> Undefined Then
			
			ThisIsRootFolderOfSource = (SourceFolder.Name = "ROOT_FOLDER_NAME");
			If ThisIsRootFolderOfSource Then
				RootDirectory = Folders.Find("ROOT_FOLDER_NAME", "Name");
				
				AddUniqueElementToList(RootDirectory.Data_FolderIds, IdOfSourceFolder);
				AddUniqueElementToList(RootDirectory.Links, IdOfSourceFolder);
				
				RootFolder_DataTemp = JSONValue(RootDirectory.Data);
				CommonClientServer.SupplementArray(
					RootFolder_DataTemp["folderIds"],
					CommonClientServer.ValueInArray(IdOfSourceFolder),
					True);
				RootDirectory.Data = ValueToJSON(RootFolder_DataTemp);
			Else
				CopySourceFolder(SourceFolder.Id, Parameters, Panel, , New_Folder.Id);
			EndIf;
			
		EndIf;
	EndDo;
	
EndProcedure

Procedure AddUniqueElementToList(List, NewItem)
	ArrayTemporary = List.UnloadValues();
	NewElementInArray = CommonClientServer.ValueInArray(NewItem);
	CommonClientServer.SupplementArray(ArrayTemporary, NewElementInArray, True);
	List.LoadValues(ArrayTemporary);
EndProcedure

Function PanelVersionIsApplicable(PanelVersion) Export
	
	GreaterThanEqualToMinimum = False;
	LessIsEqualToMaximum = False;
	
	ConfigurationVersion = StrSplit(Metadata.Version, ".", False);
	Edition    = Number(ConfigurationVersion[0]);
	Subedition = Number(ConfigurationVersion[1]);
	Version      = Number(ConfigurationVersion[2]);
	Assembly      = Number(ConfigurationVersion[3]);
	
	If IsBlankString(PanelVersion.min_config_version) Then
		GreaterThanEqualToMinimum = True;
	Else
		MinimumConfigurationVersion = StrSplit(PanelVersion.min_config_version, ".", False);
		MinEditorial    = Number(MinimumConfigurationVersion[0]);
		MinSubEdit = Number(MinimumConfigurationVersion[1]);
		MinimalVersion      = Number(MinimumConfigurationVersion[2]);
		MinKit      = Number(MinimumConfigurationVersion[3]);
		
		GreaterThanEqualToMinimum = Edition    >= MinEditorial
		                  And Subedition >= MinSubEdit
		                  And Version      >= MinimalVersion
		                  And Assembly      >= MinKit
	EndIf;
	
	If IsBlankString(PanelVersion.max_config_version) Then
		LessIsEqualToMaximum = True;
	Else
		MaximumConfigurationVersion = StrSplit(PanelVersion.max_config_version, ".", False);
		MaxEditorial    = Number(MaximumConfigurationVersion[0]);
		MaxSubEdit = Number(MaximumConfigurationVersion[1]);
		MaxVersion_      = Number(MaximumConfigurationVersion[2]);
		MaxKit      = Number(MaximumConfigurationVersion[3]);
		
		LessIsEqualToMaximum = Edition    <= MaxEditorial
		                   And Subedition <= MaxSubEdit
		                   And Version      <= MaxVersion_
		                   And Assembly      <= MaxKit
	EndIf;
	
	Result = GreaterThanEqualToMinimum And LessIsEqualToMaximum;
	
	Return Result;
	
EndFunction


Function ManifestID() Export
	
	Id = "Manifest_AnalyticsPanels_Trade_11_5";
	
	Id = "Manifest_AnalyticsPanels_ARA_2_5";
	
	Id = "Manifest_AnalyticsPanels_ERP_2_5";
	
	Return Id;
	
EndFunction

Procedure RecordRelatedAdditionalSources(ObjectID, AdditionalSources, PanelSettingsIds, ServerAddress, SourceFromFile);
	
	
EndProcedure


// Returns the contents of temporary files received from temporary storage at the specified addresses.
//
// Parameters:
//   Address - Array of String, String - An address or array of addresses in temporary storage containing binary data of temporary files.
//
// Returns:
//   Array of String - Array of strings containing the contents of temporary files.
//
Function ContentsOfTemporaryFile(Address) Export
	
	If TypeOf(Address) = Type("Array") Then
		Addresses = Address;
	Else
		Addresses = CommonClientServer.ValueInArray(Address);
	EndIf;
	
	Content = New Array;
	
	For Each TempStorageAddress In Addresses Do
		TempFileName = GetTempFileName();
		Data = GetFromTempStorage(TempStorageAddress); //BinaryData
		Data.Write(TempFileName);
		
		NewTextDocument = New TextDocument();
		NewTextDocument.Read(TempFileName, TextEncoding.UTF8);
		Content.Add(NewTextDocument.GetText());
		
		DeleteFromTempStorage(TempStorageAddress);
		DeleteFiles(TempFileName);
	EndDo;
	
	Return Content;
	
EndFunction

#EndRegion

#EndIf