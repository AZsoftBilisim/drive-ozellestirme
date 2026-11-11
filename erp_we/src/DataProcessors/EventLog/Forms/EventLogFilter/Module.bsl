///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillImportanceAndStatus();
	FillFilterParameters();
	
	DefaultEvents = Parameters.DefaultEvents;
	If DefaultEvents.Count() <> Events.Count() Then
		EventsToDisplay = Events.Copy();
	EndIf;
	
	SeparationVisibility = Not Common.SeparatedDataUsageAvailable();
	StandardSeparatorsOnly = EventLog.StandardSeparatorsOnly();
	Items.SessionDataSeparation.Visible = SeparationVisibility And Not StandardSeparatorsOnly;
	Items.DataAreas.Visible = SeparationVisibility And StandardSeparatorsOnly;
	If Items.DataAreas.Visible Then
		For Each ListItem In SessionDataSeparation Do
			If StrStartsWith(ListItem.Value, "DataAreaMainData") Then
				StringParts1 = StrSplit(ListItem.Value, "=");
				DataAreas = EventLog.StringDelimitersList(StringParts1[1]);
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "EventLogFilterItemValueChoice"
	   And Source.UUID = UUID Then
		If PropertyCompositionEditorItemName = Items.Users.Name Then
			UsersList = Parameter;
		ElsIf PropertyCompositionEditorItemName = Items.Events.Name Then
			Events = Parameter;
		ElsIf PropertyCompositionEditorItemName = Items.Computers.Name Then
			Computers = Parameter;
		ElsIf PropertyCompositionEditorItemName = Items.Applications.Name Then
			Applications = Parameter;
		ElsIf PropertyCompositionEditorItemName = Items.Metadata.Name Then
			Metadata = Parameter;
		ElsIf PropertyCompositionEditorItemName = Items.WorkingServers.Name Then
			WorkingServers = Parameter;
		ElsIf PropertyCompositionEditorItemName = Items.PrimaryIPPorts.Name Then
			PrimaryIPPorts = Parameter;
		ElsIf PropertyCompositionEditorItemName = Items.SecondaryIPPorts.Name Then
			SecondaryIPPorts = Parameter;
		ElsIf PropertyCompositionEditorItemName = Items.DataAreas.Name Then
			DataAreas = Parameter;
			SessionDataSeparation = CompleteListOfSeparators(Parameter);
		ElsIf PropertyCompositionEditorItemName = Items.SessionDataSeparation.Name Then
			SessionDataSeparation = Parameter;
		EndIf;
	EndIf;
	
	EventsToDisplay.Clear();
	
	If Events.Count() = 0 Then
		Events = DefaultEvents;
		Return;
	EndIf;
	
	If DefaultEvents.Count() <> Events.Count() Then
		EventsToDisplay = Events.Copy();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	EventsToDisplay.Clear();

	If Events.Count() = 0 Then
		Events = DefaultEvents;
		Return;
	EndIf;

	If Not CommonClientServer.ValueListsAreEqual(DefaultEvents, Events) Then
		EventsToDisplay = Events.Copy();
	EndIf;
	
	Items.Data.Visible = Not DataMultipleValues;
	Items.Data_List.Visible = DataMultipleValues;
	
	RefreshFormGroupTitles();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ChoiceCompletion(Item, ChoiceData, StandardProcessing)
	
	Var ListToEdit, ParametersToSelect;
	
	DisableStandardProcessing = True;
	PropertyCompositionEditorItemName = Item.Name;
	
	If PropertyCompositionEditorItemName = Items.Users.Name Then
		ListToEdit = UsersList;
		ParametersToSelect = "User";
	ElsIf PropertyCompositionEditorItemName = Items.Events.Name Then
		ListToEdit = Events;
		ParametersToSelect = "Event";
	ElsIf PropertyCompositionEditorItemName = Items.Computers.Name Then
		ListToEdit = Computers;
		ParametersToSelect = "Computer";
	ElsIf PropertyCompositionEditorItemName = Items.Applications.Name Then
		ListToEdit = Applications;
		ParametersToSelect = "ApplicationName";
	ElsIf PropertyCompositionEditorItemName = Items.Metadata.Name Then
		ListToEdit = Metadata;
		ParametersToSelect = "Metadata";
	ElsIf PropertyCompositionEditorItemName = Items.WorkingServers.Name Then
		ListToEdit = WorkingServers;
		ParametersToSelect = "ServerName";
	ElsIf PropertyCompositionEditorItemName = Items.PrimaryIPPorts.Name Then
		ListToEdit = PrimaryIPPorts;
		ParametersToSelect = Port();
	ElsIf PropertyCompositionEditorItemName = Items.SecondaryIPPorts.Name Then
		ListToEdit = SecondaryIPPorts;
		ParametersToSelect = "SyncPort";
	ElsIf PropertyCompositionEditorItemName = Items.DataAreas.Name Then
		ListToEdit = DataAreas;
		ParametersToSelect = "SessionDataSeparationValues" + "." + "DataAreaMainData";
	ElsIf PropertyCompositionEditorItemName = Items.SessionDataSeparation.Name Then
		StandardProcessing = False;
		FormParameters = New Structure;
		FormParameters.Insert("ActiveFilter", SessionDataSeparation);
		OpenForm("DataProcessor.EventLog.Form.SessionDataSeparation", FormParameters, ThisObject);
		Return;
	Else
		DisableStandardProcessing = False;
		Return;
	EndIf;
	
	If DisableStandardProcessing Then
		StandardProcessing = False;
	EndIf;
	
	FormParameters = New Structure;
	
	FormParameters.Insert("ListToEdit", ListToEdit);
	FormParameters.Insert("ParametersToSelect", ParametersToSelect);
	
	// Open the property editor.
	OpenForm("DataProcessor.EventLog.Form.PropertyCompositionEditor",
	             FormParameters,
	             ThisObject);
	
EndProcedure

&AtClient
Procedure DataAreasClearing(Item, StandardProcessing)
	
	SessionDataSeparation.Clear();
	
EndProcedure

&AtClient
Procedure EventsClearing(Item, StandardProcessing)
	
	Events = DefaultEvents;
	
EndProcedure

&AtClient
Procedure FilterPeriodOnChange(Item)
	
	HandlerNotifications = New CallbackDescription("FilterPeriodOnChangeCompletion", ThisObject);
	
	Dialog = New StandardPeriodEditDialog;
	Dialog.Period = FilterDateRange;
	Dialog.Show(HandlerNotifications);
	
EndProcedure

&AtClient
Procedure FilterPeriodOnChangeCompletion(Period, AdditionalParameters) Export
	
	If Period = Undefined Then
		Return;
	EndIf;
	
	FilterDateRange = Period;
	FilterPeriodStartDate    = FilterDateRange.StartDate;
	FilterPeriodEndDate = FilterDateRange.EndDate;
	
EndProcedure

&AtClient
Procedure FilterPeriodDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	FilterDateRange.Variant       = StandardPeriodVariant.Custom;
	FilterDateRange.StartDate    = FilterPeriodStartDate;
	FilterDateRange.EndDate = FilterPeriodEndDate;
	
EndProcedure

&AtClient
Procedure MultipleValuesOnChange(Item)
	
	DataName = Items.Data.Name;
	DataListName = Items.Data_List.Name;
	SingleValue = Not DataMultipleValues;
	
	Items[DataName].Visible = SingleValue;
	Items[DataListName].Visible = Not SingleValue;
	CurrentData = ThisObject[DataName];
	CurrentList = ThisObject[DataListName];
	
	If SingleValue Then
		ThisObject[DataName] = ?(CurrentList.Count() = 0,
			Undefined, CurrentList[0].Value);
		
	ElsIf ValueIsFilled(CurrentData)
	      Or CurrentList.Count() > 0 Then
		
		If CurrentList.Count() = 0 Then
			CurrentList.Add();
		EndIf;
		CurrentList[0].Value = CurrentData;
	EndIf;
	
EndProcedure

&AtClient
Procedure CommentOnChange(Item)
	
	UpdateCommentField(ThisObject);
	
EndProcedure

&AtClient
Procedure CommentEditTextChange(Item, Text, StandardProcessing)
	
	UpdateCommentField(ThisObject, Text);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetFilterAndCloseForm(Command)
	
	NotifyChoice(
		New Structure("Event, Filter", 
			"EventLogFilterSet", 
			GetEventLogFilter()));
	
EndProcedure

&AtClient
Procedure SelectSeverityCheckBoxes(Command)
	For Each ListItem In Importance Do
		ListItem.Check = True;
	EndDo;
EndProcedure

&AtClient
Procedure ClearSeverityCheckBoxes(Command)
	For Each ListItem In Importance Do
		ListItem.Check = False;
	EndDo;
EndProcedure

&AtClient
Procedure SelectTransactionStatusesCheckBoxes(Command)
	For Each ListItem In TransactionStatus Do
		ListItem.Check = True;
	EndDo;
EndProcedure

&AtClient
Procedure ClearTransactionStatuses(Command)
	For Each ListItem In TransactionStatus Do
		ListItem.Check = False;
	EndDo;
EndProcedure

&AtClient
Procedure SaveSettingsToFile(Command)

	TempStorageAddress =  SaveSettingsToTempStorage();
	
	FileSavingParameters = FileSystemClient.FileSavingParameters();                            
	FileSavingParameters.Dialog.Filter = NStr("vi = 'Lọc nhật ký sự kiện';
												|ru = 'Настройки журнала регистрации';
												|en = 'Event log settings'; fa = 'Event log settings';
												|it = 'Event log settings';
												|pl = 'Event log settings';
												|tr = 'Olay günlüğü ayarları'") + "(*.xml)|*.xml";
	FileSystemClient.SaveFile(Undefined, TempStorageAddress, "Settings.xml", FileSavingParameters);
	
EndProcedure

&AtClient
Procedure ImportSettingsFromFile(Command)
	
	FileImportParameters = FileSystemClient.FileImportParameters();   
	FileImportParameters.Dialog.Title = NStr("vi = 'Hãy chọn tệp có tùy chỉnh lọc nhật ký sự kiện';
											|ru = 'Выберите файл с настройками отбора журнала регистрации';
											|en = 'Choose a file with event log filter settings'; fa = 'Choose a file with event log filter settings';
											|it = 'Choose a file with event log filter settings';
											|pl = 'Choose a file with event log filter settings';
											|tr = 'Olay günlüğü seçim ayarları aracılığıyla dosyayı seçin'");
	FileImportParameters.Dialog.Filter = NStr("vi = 'Tệp xml';
												|ru = 'Файл xml';
												|en = 'XML file'; fa = 'XML file';
												|it = 'XML file';
												|pl = 'XML file';
												|tr = 'xml dosyası'") + "(*.xml)|*.xml";
	
	CallbackDescription = New CallbackDescription("ImportSettingsFromFileCompletion", ThisObject);
	FileSystemClient.ImportFile_(CallbackDescription, FileImportParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillImportanceAndStatus()
	// Filling the Importance form item
	Importance.Add("Error",         String(EventLogLevel.Error));
	Importance.Add("Warning", String(EventLogLevel.Warning));
	Importance.Add("Information",     String(EventLogLevel.Information));
	Importance.Add("Note",     String(EventLogLevel.Note));
	
	// Filling the TransactionStatus form item
	TransactionStatus.Add("NotApplicable", String(EventLogEntryTransactionStatus.NotApplicable));
	TransactionStatus.Add("Committed", String(EventLogEntryTransactionStatus.Committed));
	TransactionStatus.Add("Unfinished",   String(EventLogEntryTransactionStatus.Unfinished));
	TransactionStatus.Add("RolledBack",      String(EventLogEntryTransactionStatus.RolledBack));
	
EndProcedure

&AtServer
Procedure FillFilterParameters()
	
	FilterParameterList = Parameters.Filter;
	HasFilterByLevel  = False;
	HasFilterByStatus = False;
	
	For Each FilterParameter In FilterParameterList Do
		ParameterName = FilterParameter.Presentation;
		Value     = FilterParameter.Value;
		
		If Upper(ParameterName) = Upper("StartDate") Then
			// StartDate.
			FilterDateRange.StartDate = Value;
			FilterPeriodStartDate  = Value;
			
		ElsIf Upper(ParameterName) = Upper("EndDate") Then
			// EndDate.
			FilterDateRange.EndDate = Value;
			FilterPeriodEndDate  = Value;
			
		ElsIf Upper(ParameterName) = Upper("User") Then
			// User.
			UsersList = Value;
			
		ElsIf Upper(ParameterName) = Upper("Event") Then
			// Event.
			Events = Value;
			
		ElsIf Upper(ParameterName) = Upper("Computer") Then
			// Computer.
			Computers = Value;
			
		ElsIf Upper(ParameterName) = Upper("ApplicationName") Then
			// ApplicationName.
			Applications = Value;
			
		ElsIf Upper(ParameterName) = Upper("Comment") Then
			// Comment.
			Comment = Value;
			UpdateCommentField(ThisObject);
			
		ElsIf Upper(ParameterName) = Upper("Metadata") Then
			// Metadata.
			Metadata = Value;
			
		ElsIf Upper(ParameterName) = Upper("Data") Then
			// Data. 
			If TypeOf(Value) = Type("ValueList") Then
				DataMultipleValues = True;
				Items.Data.Visible = False;
				Items.Data_List.Visible = True;
				Data_List = Value;
			Else
				Data = Value;
			EndIf;
			
		ElsIf Upper(ParameterName) = Upper("DataPresentation") Then
			// DataPresentation.
			DataPresentation = Value;
			
		ElsIf Upper(ParameterName) = Upper("Transaction") Then
			// TransactionID.
			Transaction = Value;
			
		ElsIf Upper(ParameterName) = Upper("ServerName") Then
			// ServerName.
			WorkingServers = Value;
			
		ElsIf Upper(ParameterName) = Upper("Session") Then
			// Session.
			Sessions = Value;
			SessionsString = "";
			For Each SessionNumber In Sessions Do
				SessionsString = SessionsString + ?(SessionsString = "", "", "; ") + SessionNumber;
			EndDo;
			
		ElsIf Upper(ParameterName) = Upper(Port()) Then
			// Port.
			PrimaryIPPorts = Value;
			
		ElsIf Upper(ParameterName) = Upper("SyncPort") Then
			// SyncPort.
			SecondaryIPPorts = Value;
			
		ElsIf Upper(ParameterName) = Upper("Level") Then
			// Level.
			HasFilterByLevel = True;
			For Each ValueListItem In Importance Do
				If Value.FindByValue(ValueListItem.Value) <> Undefined Then
					ValueListItem.Check = True;
				EndIf;
			EndDo;
			
		ElsIf Upper(ParameterName) = Upper("TransactionStatus") Then
			// TransactionStatus.
			HasFilterByStatus = True;
			For Each ValueListItem In TransactionStatus Do
				If Value.FindByValue(ValueListItem.Value) <> Undefined Then
					ValueListItem.Check = True;
				EndIf;
			EndDo;
			
		ElsIf Upper(ParameterName) = Upper("SessionDataSeparation") Then
			
			If TypeOf(Value) = Type("ValueList") Then
				SessionDataSeparation = Value.Copy();
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If Not HasFilterByLevel Then
		For Each ValueListItem In Importance Do
			ValueListItem.Check = True;
		EndDo;
	EndIf;
	
	If Not HasFilterByStatus Then
		For Each ValueListItem In TransactionStatus Do
			ValueListItem.Check = True;
		EndDo;
	ElsIf HasFilterByStatus Or ValueIsFilled(Transaction) Then
		Items.TransactionsGroup.Title = Items.TransactionsGroup.Title + " *";
	EndIf;
	
	If ValueIsFilled(WorkingServers)
		Or ValueIsFilled(PrimaryIPPorts)
		Or ValueIsFilled(SecondaryIPPorts) Then
		Items.OthersGroup.Title = Items.OthersGroup.Title + " *";
	EndIf;
	
EndProcedure

&AtClient
Function GetEventLogFilter()
	
	Sessions.Clear();
	Page1 = SessionsString;
	Page1 = StrReplace(Page1, ";", " ");
	Page1 = StrReplace(Page1, ",", " ");
	Page1 = TrimAll(Page1);
	TS = New TypeDescription("Number");
	
	While Not IsBlankString(Page1) Do
		Pos = StrFind(Page1, " ");
		
		If Pos = 0 Then
			Value = TS.AdjustValue(Page1);
			Page1 = "";
		Else
			Value = TS.AdjustValue(Left(Page1, Pos-1));
			Page1 = TrimAll(Mid(Page1, Pos+1));
		EndIf;
		
		If Value <> 0 Then
			Sessions.Add(Value);
		EndIf;
	EndDo;
	
	Filter = New ValueList;
	
	// Start and end dates.
	If FilterPeriodStartDate <> '00010101000000' Then 
		Filter.Add(FilterPeriodStartDate, "StartDate");
	EndIf;
	If FilterPeriodEndDate <> '00010101000000' Then
		Filter.Add(FilterPeriodEndDate, "EndDate");
	EndIf;
	
	// User.
	If UsersList.Count() > 0 Then 
		Filter.Add(UsersList, "User");
	EndIf;
	
	// Event.
	If Events.Count() > 0 Then 
		Filter.Add(Events, "Event");
	EndIf;
	
	// Computer.
	If Computers.Count() > 0 Then 
		Filter.Add(Computers, "Computer");
	EndIf;
	
	// ApplicationName.
	If Applications.Count() > 0 Then 
		Filter.Add(Applications, "ApplicationName");
	EndIf;
	
	// Comment.
	If Not IsBlankString(Comment) Then 
		Filter.Add(Comment, "Comment");
	EndIf;
	
	// Metadata.
	If Metadata.Count() > 0 Then 
		Filter.Add(Metadata, "Metadata");
	EndIf;
	
	// Data. 
	FilterValue = ?(DataMultipleValues, Data_List, Data);
	If ValueIsFilled(FilterValue) Then
		Filter.Add(FilterValue, "Data");
	EndIf;
	
	// DataPresentation.
	If Not IsBlankString(DataPresentation) Then 
		Filter.Add(DataPresentation, "DataPresentation");
	EndIf;
	
	// TransactionID.
	If Not IsBlankString(Transaction) Then 
		Filter.Add(Transaction, "Transaction");
	EndIf;
	
	// ServerName.
	If WorkingServers.Count() > 0 Then 
		Filter.Add(WorkingServers, "ServerName");
	EndIf;
	
	// Session.
	If Sessions.Count() > 0 Then 
		Filter.Add(Sessions, "Session");
	EndIf;
	
	// Port.
	If PrimaryIPPorts.Count() > 0 Then 
		Filter.Add(PrimaryIPPorts, "Port");
	EndIf;
	
	// SyncPort.
	If SecondaryIPPorts.Count() > 0 Then 
		Filter.Add(SecondaryIPPorts, "SyncPort");
	EndIf;
	
	// SessionDataSeparation.
	If SessionDataSeparation.Count() > 0 Then 
		Filter.Add(SessionDataSeparation, "SessionDataSeparation");
	EndIf;
	
	// Level.
	LevelList = New ValueList;
	For Each ValueListItem In Importance Do
		If ValueListItem.Check Then 
			LevelList.Add(ValueListItem.Value, ValueListItem.Presentation);
		EndIf;
	EndDo;
	If LevelList.Count() > 0 And LevelList.Count() <> Importance.Count() Then
		Filter.Add(LevelList, "Level");
	EndIf;
	
	// TransactionStatus.
	StatusesList = New ValueList;
	For Each ValueListItem In TransactionStatus Do
		If ValueListItem.Check Then 
			StatusesList.Add(ValueListItem.Value, ValueListItem.Presentation);
		EndIf;
	EndDo;
	If StatusesList.Count() > 0 And StatusesList.Count() <> TransactionStatus.Count() Then
		Filter.Add(StatusesList, "TransactionStatus");
	EndIf;
	
	Return Filter;
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdateCommentField(Form, Text = Undefined)
	
	If Text = Undefined Then
		Text = Form.Comment;
	EndIf;
	
	Rows = StrSplit(Text, Chars.LF);
	If Rows.Count() > 1 Then
		NewHeight = 2;
	Else
		NewHeight = 1;
	EndIf;
	
	If Form.Items.Comment.Height <> NewHeight Then
		Form.Comment = Text;
		Form.Items.Comment.Height = NewHeight;
	EndIf;
	
	MaxLength = 1;
	For Each String In Rows Do
		If StrLen(String) > MaxLength Then
			MaxLength = StrLen(String);
		EndIf;
	EndDo;
	
	If MaxLength > 70 Then
		NewStretch = True;
	Else
		NewStretch = False;
	EndIf;
	
	If Form.Items.Comment.HorizontalStretch <> NewStretch Then
		Form.Comment = Text;
		Form.Items.Comment.HorizontalStretch = NewStretch;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CompleteListOfSeparators(Parameter)
	
	Presentations = New Array;
	For Each ListItem In Parameter Do
		If ValueIsFilled(ListItem.Presentation) Then
			Presentations.Add(ListItem.Presentation);
		Else
			Presentations.Add(ListItem.Value);
		EndIf;
	EndDo;
	
	ValuesPresentation = StrConcat(Presentations, ", ");
	StringValues = StrConcat(Parameter.UnloadValues(), ",");
	
	List = New ValueList;
	
	For Each CommonAttribute In Metadata.CommonAttributes Do
		If CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.DontUse Then
			Continue;
		EndIf;
		SeparatorPresentation = CommonAttribute.Presentation() + " = " + ValuesPresentation;
		SeparatorValue = CommonAttribute.Name + "=" + StringValues;
		List.Add(SeparatorValue, SeparatorPresentation);
	EndDo;
	
	Return List;
	
EndFunction

&AtServer
Procedure RefreshFormGroupTitles()
	
	SelectedStatusesCount = CommonClientServer.MarkedItems(TransactionStatus).Count();
	If SelectedStatusesCount <> TransactionStatus.Count() 
		Or ValueIsFilled(Transaction) Then
		Items.TransactionsGroup.Title = Items.TransactionsGroup.Title + " *";
	EndIf;
	
	If ValueIsFilled(WorkingServers)
		Or ValueIsFilled(PrimaryIPPorts)
		Or ValueIsFilled(SecondaryIPPorts) Then
		Items.OthersGroup.Title = Items.OthersGroup.Title + " *";
	EndIf;
	
EndProcedure

&AtServer
Function SaveSettingsToTempStorage() 
			
	SavingSettings = SavingSettings();
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XMLWriter.WriteXMLDeclaration();
	XMLWriter.WriteStartElement("Filters");

	XMLWriter.WriteStartElement("MainFilters");
	XDTOSerializer.WriteXML(XMLWriter, SavingSettings, XMLTypeAssignment.Explicit);

	XMLWriter.WriteEndElement();
	
	If DataMultipleValues Then		
		For Each FilteredData In Data_List Do
			XMLWriter.WriteStartElement("DataFilters");
			XDTOSerializer.WriteXML(XMLWriter, FilteredData.Value, XMLTypeAssignment.Explicit);
			XMLWriter.WriteEndElement();
		EndDo;		
	ElsIf ValueIsFilled(Data) Then
   		XMLWriter.WriteStartElement("DataFilters");	
		XDTOSerializer.WriteXML(XMLWriter, Data, XMLTypeAssignment.Explicit);		
		XMLWriter.WriteEndElement();
	EndIf;
     	
	XMLWriter.WriteEndElement();

	XMLLine = XMLWriter.Close();
	
	BinaryData = GetBinaryDataFromString(XMLLine);
    TempFileStorageAddress = PutToTempStorage(BinaryData, UUID);
	
	Return TempFileStorageAddress;
	
EndFunction

&AtServer
Function SavingSettings()
	
	SavingSettings = New ValueList();
	SavingSettings.Add(Importance, "Level");
	If CommonClientServer.ValueListsAreEqual(DefaultEvents, Events) Then
		SavingSettings.Add(New ValueList(), "Event");
	Else
		SavingSettings.Add(Events, "Event");
	EndIf;
	SavingSettings.Add(Metadata, "Metadata");
	SavingSettings.Add(FilterPeriodStartDate, "StartDate");
	SavingSettings.Add(FilterPeriodEndDate, "EndDate");
	SavingSettings.Add(UsersList, "User");
	SavingSettings.Add(Applications, "ApplicationName");
	SavingSettings.Add(Computers, "Computer");
	SavingSettings.Add(SessionsString, "Sessions");
	SavingSettings.Add(DataPresentation, "DataPresentation");
	SavingSettings.Add(TransactionStatus, "TransactionStatus");
	SavingSettings.Add(WorkingServers, "ServerName");
	SavingSettings.Add(SessionDataSeparation, "SessionDataSeparation");
	SavingSettings.Add(Transaction, "TransactionID");
	SavingSettings.Add(Comment, "Comment");   
	SavingSettings.Add(PrimaryIPPorts, "Port");
	SavingSettings.Add(SecondaryIPPorts, "SyncPort");
	SavingSettings.Add(DataAreas, "DataArea");
		
	Return SavingSettings;
	
EndFunction

&AtClient
Procedure ImportSettingsFromFileCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;	
	
	ImportSettingsFromFileAtServer(Result.Location);
	ShowUserNotification(NStr("vi = 'Tùy chỉnh lọc';
								|ru = 'Настройки отбора';
								|en = 'Filter settings'; fa = 'تنظیمات فیلتر';
								|it = 'Impostazioni della selezione';
								|pl = 'Ustawienia filtru';
								|tr = 'Filtre ayarları'"),, NStr("vi = 'Đã kết nhập tùy chỉnh lọc';
																|ru = 'Настройки отбора загружены';
																|en = 'Filter settings are imported'; fa = 'Filter settings are imported';
																|it = 'Filter settings are imported';
																|pl = 'Filter settings are imported';
																|tr = 'Filtre ayarları kuruldu'"));
	
EndProcedure

&AtServer
Procedure ImportSettingsFromFileAtServer(AddressInTempStorage)
	
	ListOfFilterParametersFromFile = SettingsFromFile(AddressInTempStorage);
	
	ApplySettingsFromFile(ListOfFilterParametersFromFile);
	
	EventsToDisplay.Clear();
	If Events.Count() = 0 Then
		Events = DefaultEvents;
		Return;
	EndIf;
	
	If Not CommonClientServer.ValueListsAreEqual(DefaultEvents, Events) Then
		EventsToDisplay = Events.Copy();
	EndIf;
	
EndProcedure

&AtServer
Function SettingsFromFile(AddressInTempStorage)
	
	BinaryData = GetFromTempStorage(AddressInTempStorage);

	XMLLine = GetStringFromBinaryData(BinaryData);	
	XMLReader = New XMLReader;
	XMLReader.SetString(XMLLine);
	
	DataArray = New Array;
	Filter_Settings = New ValueList;
	
	While XMLReader.Read() Do	
		 
		If XMLReader.NodeType = XMLNodeType.StartElement Then
			
			If XMLReader.Name = "MainFilters" Then
				XMLReader.Read();
				Filter_Settings = XDTOSerializer.ReadXML(XMLReader);
			ElsIf XMLReader.Name = "DataFilters" Then
				XMLReader.Read(); 			
				XMLType = XDTOSerializer.GetXMLType(XMLReader);
				If XMLType = XMLType(Type("String"))
					Or XMLType = XMLType(Type("Date"))
					Or XMLType = XMLType(Type("Number"))
					Or XMLType = XMLType(Type("Boolean")) Then
					DataArray.Add(XDTOSerializer.ReadXML(XMLReader));
				Else
					Value = XDTOSerializer.ReadXML(XMLReader);
					If ValueIsFilled(Value) 
						And TypeOf(Value) <> Type("String")
						And Common.RefExists(Value) Then
						DataArray.Add(Value);	
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
	EndDo;
	
	Filter_Settings.Add(DataArray, "Data");
	
	XMLReader.Close();
	
	Return Filter_Settings;	
	
EndFunction

&AtServer
Procedure ApplySettingsFromFile(FilterParameterList)
		
	AvailableSelections = AvailableEventLogFilters();
	
	For Each FilterParameter In FilterParameterList Do
		
		ParameterName = FilterParameter.Presentation;
		Value     = FilterParameter.Value;
		
		If Upper(ParameterName) = Upper("StartDate") Then
			// StartDate
			FilterDateRange.StartDate = Value;
			FilterPeriodStartDate  = Value;
			
		ElsIf Upper(ParameterName) = Upper("EndDate") Then
			// EndDate
			FilterDateRange.EndDate = Value;
			FilterPeriodEndDate  = Value;
			
		ElsIf Upper(ParameterName) = Upper("User") Then
			// User
			UsersList = AvailableFilterValues(Value, AvailableSelections, "User");
			
		ElsIf Upper(ParameterName) = Upper("Event") Then
			// Event
			Events = AvailableFilterValues(Value, AvailableSelections, "Event");
			
		ElsIf Upper(ParameterName) = Upper("Computer") Then
			// Computer
			Computers = AvailableFilterValues(Value, AvailableSelections, "Computer");
			
		ElsIf Upper(ParameterName) = Upper("ApplicationName") Then
			// ApplicationName
			Applications = AvailableFilterValues(Value, AvailableSelections, "ApplicationName");
			
		ElsIf Upper(ParameterName) = Upper("Comment") Then
			// Comment
			Comment = Value;
		 	
		ElsIf Upper(ParameterName) = Upper("Metadata") Then
			// Metadata
			Metadata = AvailableFilterValues(Value, AvailableSelections, "Metadata");
			
		ElsIf Upper(ParameterName) = Upper("Data") Then
			// Data
			If ValueIsFilled(Value) And Value.Count() > 1 Then 
				DataMultipleValues = True;
				Data_List.LoadValues(Value);
			ElsIf ValueIsFilled(Value) And Value.Count() = 1 Then
				DataMultipleValues = False;
				Data = Value[0];
			Else
				Data = Undefined;
				Data_List.Clear();
			EndIf;
			
			Items.Data.Visible = Not DataMultipleValues;
			Items.Data_List.Visible = DataMultipleValues;
						
		ElsIf Upper(ParameterName) = Upper("DataPresentation") Then
			// DataPresentation
			DataPresentation = Value;
			
		ElsIf Upper(ParameterName) = Upper("TransactionID") Then
			// TransactionID
			Transaction = Value;
			
		ElsIf Upper(ParameterName) = Upper("ServerName") Then
			// ServerName
			WorkingServers = AvailableFilterValues(Value, AvailableSelections, "ServerName");
			
		ElsIf Upper(ParameterName) = Upper("Sessions") Then
			// Sessions
			SessionsString = Value;
			
		ElsIf Upper(ParameterName) = Upper("Port") Then
			// Port
			PrimaryIPPorts = AvailableFilterValues(Value, AvailableSelections, "Port");
			
		ElsIf Upper(ParameterName) = Upper("SyncPort") Then
			// SyncPort
			SecondaryIPPorts = AvailableFilterValues(Value, AvailableSelections, "SyncPort");
			
		ElsIf Upper(ParameterName) = Upper("Level") Then
			// Level
			For Each ValueListItem In Importance Do
				SettingValue = Value.FindByValue(ValueListItem.Value);
				If SettingValue <> Undefined Then
					ValueListItem.Check = SettingValue.Check;
				Else
					ValueListItem.Check = False;
				EndIf;
			EndDo;
			
		ElsIf Upper(ParameterName) = Upper("TransactionStatus") Then
			// TransactionStatus
			For Each ValueListItem In TransactionStatus Do
				SettingValue = Value.FindByValue(ValueListItem.Value);
				If SettingValue <> Undefined Then
					ValueListItem.Check = SettingValue.Check;
				Else
					ValueListItem.Check = False;
				EndIf;
			EndDo;
			
		ElsIf Items.SessionDataSeparation.Visible And Upper(ParameterName) = Upper("SessionDataSeparation") Then
			// SessionDataSeparation
			If TypeOf(Value) = Type("ValueList") Then
				SessionDataSeparation = AvailableSessionDataSeparators(Value);
			EndIf;			
			
		ElsIf Items.DataAreas.Visible And Upper(ParameterName) = Upper("DataArea") Then
			// DataArea
			DataAreas = AvailableFilterValues(Value, AvailableSelections.SessionDataSeparationValues, 
				"DataAreaMainData");
			SessionDataSeparation = CompleteListOfSeparators(DataAreas);
			
		EndIf;
		
	EndDo;
	
	RefreshFormGroupTitles();
	
EndProcedure  

&AtServer
Function AvailableFilterValues(FilterValue, AvailableSelections, FilterParameterName)

	Result = New ValueList();
	
	AvailableFilterValues = AvailableSelections[FilterParameterName];
	
	If TypeOf(AvailableFilterValues) = Type("Array") Then
		For Each FilterElement In FilterValue Do
			If AvailableFilterValues.Find(FilterElement.Value) <> Undefined Then
				Result.Add(FilterElement.Value, FilterElement.Presentation);
			EndIf;			
		EndDo;
			
	ElsIf TypeOf(AvailableFilterValues) = Type("Map") Then
		For Each FilterElement In FilterValue Do
			If AvailableFilterValues[FilterElement.Value] <> Undefined Then
				Result.Add(FilterElement.Value, FilterElement.Presentation);
			EndIf;
		EndDo;
			
	ElsIf TypeOf(AvailableFilterValues) = Type("ValueList") Then
		For Each FilterElement In FilterValue Do
			ValueFound = AvailableFilterValues.FindByValue(FilterElement.Presentation);
			If ValueFound <> Undefined Then
				Result.Add(ValueFound.Presentation, ValueFound.Value);
			EndIf;
		EndDo;
		
	EndIf;
	
	Return Result;	
	
EndFunction

&AtServerNoContext
Function AvailableEventLogFilters()
	
	ParametersToSelect = "User, Event, Computer, ApplicationName, Metadata, ServerName, 
	|	PrimaryIPPort, SyncPort, SessionDataSeparation.DataAreaMainData"; 
	
	AvailableFilterParameters = GetEventLogFilterValues(ParametersToSelect);
	
	ListOfUsersToFilter = New ValueList;
	
	UsersFilterValues = AvailableFilterParameters["User"];
	
	For Each MapItem In UsersFilterValues Do
		
		ListOfUsersToFilter.Add(MapItem.Value, String(MapItem.Key));
		
	EndDo;
	
	SetPrivilegedMode(True);
	EmptyInfobaseUser = InfoBaseUsers.FindByName("");
	SetPrivilegedMode(False);
	ListOfUsersToFilter.Add(Users.UnspecifiedUserFullName(), 
		String(EmptyInfobaseUser.UUID));
	
	AvailableFilterParameters["User"] = ListOfUsersToFilter;	
	
	If Not Common.SeparatedDataUsageAvailable() Then
		AvailableFilterParameters.SessionDataSeparationValues["DataAreaMainData"].Insert("", NStr("vi = '<Chưa đặt>';
																									|ru = '<Не задано>';
																									|en = '<Not set>'; fa = '<Not set>';
																									|it = '<Non impostato>';
																									|pl = '<Nie określono>';
																									|tr = '<Belirlenmedi>'"));
	EndIf;
	
	ProcessAvailableSelectionParameters(AvailableFilterParameters);
	
	Return AvailableFilterParameters;
	
EndFunction

&AtServerNoContext
Procedure ProcessAvailableSelectionParameters(AvailableFilterParameters)
	
	For Each FilterParameter In AvailableFilterParameters Do
		If FilterParameter.Key = "SessionDataSeparationValues" Then
			ConvertedSet = New Map;
			For Each MapItem In FilterParameter.Value["DataAreaMainData"] Do
				ConvertedSet.Insert(Format(MapItem.Key, "NG="), MapItem.Value);
			EndDo;
			
			FilterParameter.Value["DataAreaMainData"] = ConvertedSet;

		EndIf
	EndDo;
	
EndProcedure

&AtServerNoContext
Function AvailableSessionDataSeparators(Value)
	
	Result = New ValueList;
	
	DataSeparationMap = New Map;
	If Value.Count() > 0 Then
		For Each SessionSeparator In Value Do
			DataSeparationArray = StrSplit(SessionSeparator.Value, "=");
			DataSeparationMap.Insert(DataSeparationArray[0], DataSeparationArray[1]);
		EndDo;                     	
	EndIf;
	
	If DataSeparationMap.Count()  = 0 Then
		Return Result;
	EndIf;
	
	For Each CommonAttribute In Metadata.CommonAttributes Do
		
		If CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.DontUse Then
			Continue;
		EndIf;
		
		FoundSeparatorValue = DataSeparationMap[CommonAttribute.Name];
		If FoundSeparatorValue <> Undefined Then
			SeparatorValue = CommonAttribute.Name + "=" + FoundSeparatorValue;
			SeparatorPresentation = CommonAttribute.Synonym + " = " + FoundSeparatorValue;
			Result.Add(SeparatorValue, SeparatorPresentation);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Returns:
//  String
//
&AtClientAtServerNoContext
Function Port()
	Return "Port";
EndFunction


#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_FilterPeriodStartDate" Then
		FilterPeriodDateOnChange(Items.StartDate);
	ElsIf Item.Name = "sh_ShamsiInput_F_FilterPeriodEndDate" Then
		FilterPeriodDateOnChange(Items.EndDate);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
