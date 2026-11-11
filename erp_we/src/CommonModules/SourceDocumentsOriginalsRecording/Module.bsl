///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region FormsEventsHandlers

// Handler of the "OnCreateAtServer" document form event.
//
// Parameters:
//  Form - ClientApplicationForm:
//   * Object - FormDataStructure, DocumentObject - Form's main attribute.
//  Placement - FormGroup - a group where a label with the current original state will be located.
//		           If Undefined, the label will be located in the lower right corner of the form. Optional. 
//
Procedure OnCreateAtServerDocumentForm(Form, Placement = Undefined) Export

	If GetFunctionalOption("UseSourceDocumentsOriginalsRecording") = False
	Or Not AccessRight("Read", Metadata.InformationRegisters.SourceDocumentsOriginalsStates) Then
		DecorationToDisable = Form.Items.Find("OriginalStateDecoration");
		If Not DecorationToDisable = Undefined Then
			DecorationToDisable.Visible = False;
		EndIf;
		Return;
	EndIf;
	
	Settings = SubsystemSettings(); 
	
	If Settings.ShouldDisplayButtonsOnDocumentForm Then 
		If Not Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
			OutputOriginalStateCommandsToForm(Form, Undefined, UsedStates());
		EndIf;
		ConfigureButtonsOnDocumentForm(Form);
	Else
		ConfigureHyperlinkOnDocumentForm(Form, Placement);
	EndIf;

EndProcedure

// Handler of the "OnCreateAtServer" list form event.
//
// Parameters:
//  Form - ClientApplicationForm - a document list form.
//  List - FormTable - the main form list.
//  Placement - FormField - a list column next to which new columns of states will be located.
//		                       If Undefined, the columns will be located at the end of the list. Optional.
//
Procedure OnCreateAtServerListForm(Form, List, Placement = Undefined) Export

	If GetFunctionalOption("UseSourceDocumentsOriginalsRecording") = False
	Or Not AccessRight("Read",Metadata.InformationRegisters.SourceDocumentsOriginalsStates) Then
		ColumnToDisable = Form.Items.Find("StateOriginalReceived");
		If Not ColumnToDisable = Undefined Then
			ColumnToDisable.Visible = False;
		EndIf;
		Return;
	EndIf;
	
	// Create columns in the dynamic list.
	AttributeListStateReceived = Form.Items.Insert("StateOriginalReceived",Type("FormField"),List,Placement);
	AttributeListStateReceived.Type = FormFieldType.PictureField;
	AttributeListStateReceived.TitleLocation = FormItemTitleLocation.None; 
	AttributeListStateReceived.ValuesPicture = PictureLib.IconsCollectionSourceDocumentOriginalAvailable;
	AttributeListStateReceived.HeaderPicture = PictureLib.SourceDocumentOriginalStateOriginalReceived;
	AttributeListStateReceived.Title = NStr("vi = 'Đã nhận trạng thái bản gốc';
											|ru = 'Состояние оригинал получен';
											|en = 'Status ""Hard copy received""'; fa = 'Status ""Hard copy received""';
											|it = 'Состояние оригинал получен';
											|pl = 'Status ""Hard copy received""';
											|tr = 'Durum aslı alındı'");
	AttributeListStateReceived.DataPath = List.Name + ".StateOriginalReceived";
	
	AttributeListState = Form.Items.Insert("SourceDocumentOriginalState",Type("FormField"),List,Placement);
	AttributeListState.Type = FormFieldType.LabelField;
	AttributeListState.CellHyperlink = True;
	AttributeListState.Title = NStr("vi = 'Trạng thái bản gốc';
									|ru = 'Состояние оригинала';
									|en = 'Original state'; fa = 'وضعیت اصل';
									|it = 'Stato dell''originale';
									|pl = 'Status oryginała';
									|tr = 'Aslın durumu'");
	AttributeListState.DataPath = List.Name + ".SourceDocumentOriginalState";
	
	If Not RightsToChangeState() Then
		AttributeListStateReceived.Enabled = False;
		AttributeListState.Enabled = False;
		Return;
	EndIf;
	
	// Create a list.
	Attributes = New Array;
	Attributes.Add(New FormAttribute("OriginalStatesChoiceList", New TypeDescription("ValueList")));
	Form.ChangeAttributes(Attributes);
	
	OriginalsStates = UsedStates();
	
	If Not Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		OutputOriginalStateCommandsToForm(Form, List, OriginalsStates);
	EndIf;

	FillOriginalStatesChoiceList(Form, OriginalsStates);

EndProcedure

// Handler of the "OnGetDataAtServer" list form event.
//
// Parameters:
//  ListRows - DynamicListRows - Document list rows.
//
Procedure OnGetDataAtServer(ListRows) Export
	
	If GetFunctionalOption("UseSourceDocumentsOriginalsRecording") = False 
	Or Not AccessRight("Read",Metadata.InformationRegisters.SourceDocumentsOriginalsStates) Then
		Return;
	EndIf;
	
	References = New Array;
	KeyFieldName = "Ref";
	 
	For Each ListLine In ListRows Do
		ListLine = ListRows[ListLine.Key]; 
		If Not ListLine.Data.Property("Ref")
			Or (ListLine.Appearance.Get("SourceDocumentOriginalState") = Undefined 
			And ListLine.Appearance.Get("StateOriginalReceived") = Undefined) Then
			Return;
		EndIf;
		References.Add(ListLine.Data[KeyFieldName]);
	EndDo;
	
	Query = New Query;
	Query.Text = "SELECT
	               |	SourceDocumentsOriginalsStates.State AS SourceDocumentOriginalState,
	               |	SourceDocumentsOriginalsStates.OverallState AS OverallState,
	               |	CASE
	               |		WHEN SourceDocumentsOriginalsStates.State = VALUE(Catalog.SourceDocumentsOriginalsStates.OriginalReceived)
	               |			THEN 1
	               |		ELSE 0
	               |	END AS StateOriginalReceived,
	               |	SourceDocumentsOriginalsStates.Owner AS Ref
	               |FROM
	               |	InformationRegister.SourceDocumentsOriginalsStates AS SourceDocumentsOriginalsStates
	               |WHERE
	               |	SourceDocumentsOriginalsStates.OverallState
	               |	AND SourceDocumentsOriginalsStates.Owner IN(&Ref)"; 

	Query.SetParameter("Ref", References);
	
	ColorOfHyperlink = StyleColors.HyperlinkColor;
	InactiveHyperlinkColor = StyleColors.InaccessibleCellTextColor;
	
	Selection = Query.Execute().Select();
	If Not ListLine.Appearance.Get("SourceDocumentOriginalState") = Undefined Then
		For Each String In ListRows Do
			String = ListRows[String.Key];
			Selection.Reset();
			If Selection.FindNext(String.Data["Ref"], "Ref") Then 
				
				String.Data["SourceDocumentOriginalState"] = Selection.SourceDocumentOriginalState;
				String.Appearance["SourceDocumentOriginalState"].SetParameterValue("TextColor", ColorOfHyperlink);
			Else
				String.Data["SourceDocumentOriginalState"] = NStr("vi = '<Không xác định>';
																	|ru = '<Неизвестно>';
																	|en = '<Unknown>'; fa = '<Unknown>';
																	|it = '<Sconosciuto>';
																	|pl = '<Unknown>';
																	|tr = '<Bilinmiyor>'");
				String.Appearance["SourceDocumentOriginalState"].SetParameterValue("TextColor", InactiveHyperlinkColor);
			EndIf;
		EndDo;
	EndIf;
	
	If Not ListLine.Appearance.Get("StateOriginalReceived") = Undefined Then
		For Each String In ListRows Do
			String = ListRows[String.Key];
			Selection.Reset();
			If Selection.FindNext(String.Data["Ref"], "Ref") Then 
				String.Data["StateOriginalReceived"] = Selection.StateOriginalReceived;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

// Called in order to write new or modified states of source document originals.
//
// Parameters:
//  WritingObjects - Array of Structure - Array of data on the original's state being modified 
//										  (in case of batch change of document state):
//                 * OverallState    - Boolean - "True" if the current state is aggregated.
//                 * Ref 		   - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - The document whose 
//												  source document's state should be changed.
//                 * SourceDocumentOriginalState - CatalogRef.SourceDocumentsOriginalsStates -
//                                                           The current state of a source document.
//                 * SourceDocument - String - A source document ID. 
//                                                Required if the state is not aggregated.
//                 * FromOutside 			   - Boolean - "True" if the source document was added manually. 
//                                                It's required if the current state is not aggregated.
//                - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - Reference to the document whose source document's state
//												  should be changed (in case of a singular change).
//  OriginalState - CatalogRef.SourceDocumentsOriginalsStates - Reference to the state to apply.
//
// Returns:
//  String - "IsChanged" if the source document state is not repeated and was saved.
//           "NotIsChanged"
//           "NotCarriedOut"
//
Function SetNewOriginalState(Val WritingObjects, Val OriginalState) Export

	If Not GetFunctionalOption("UseSourceDocumentsOriginalsRecording") Then
		Return "NotIsChanged";
	EndIf;
	
	VerifyAccessRights("Edit", Metadata.InformationRegisters.SourceDocumentsOriginalsStates);
	
	RecordArray = New Array;
	ReferencesArrray = New Array;
	If TypeOf(WritingObjects) = Type("Array") Then 
		For Each Object In WritingObjects Do
			Ref = Object.Ref;
			If IsAccountingObject(Ref) Then
				ReferencesArrray.Add(Ref);
				RecordArray.Add(Object);
			EndIf;
		EndDo;
	Else
		ReferencesArrray.Add(WritingObjects);
		RecordArray = WritingObjects;
	EndIf;

	UnpostedDocuments = Common.CheckDocumentsPosting(ReferencesArrray);
	If UnpostedDocuments.Count() > 0 Then
		Return "NotConducted";
	EndIf;
	
	SetPrivilegedMode(True);
	If TypeOf(WritingObjects) = Type("Array") Then
		 Result = SetTheNewStateOfTheOriginalArray(RecordArray, OriginalState);
	Else
		 Result = SetNewStatusForOriginalDoc(RecordArray, OriginalState);
	EndIf;
	Return ?(Result, "IsChanged", "NotIsChanged");
	
EndFunction

// Returns data on the current aggregated state of the source document by Ref.
//
//	Parameters:
//  Document - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - Reference to the document whose
//																			aggregated state information is to be received. 
//
//  Returns:
//    Structure:
//    * Ref - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - Document reference.
//    * SourceDocumentOriginalState - CatalogRef.SourceDocumentsOriginalsStates - Current aggregated state
//        of the original document.
//
Function OriginalStateInfoByRef(Document) Export

	Query = New Query;
	Query.Text = "SELECT ALLOWED
		|	SourceDocumentsOriginalsStates.State AS State
		|FROM
		|	InformationRegister.SourceDocumentsOriginalsStates AS SourceDocumentsOriginalsStates
		|WHERE
		|	SourceDocumentsOriginalsStates.Owner = &Ref
		|	AND SourceDocumentsOriginalsStates.OverallState = TRUE";
	
	Query.SetParameter("Ref", Document);
	
	StateInfo3 = New Structure;

	If Not Query.Execute().IsEmpty() Then
		Selection = Query.Execute().Select();
		Selection.Next();
		
		StateInfo3.Insert("Ref", Document);
		StateInfo3.Insert("SourceDocumentOriginalState", Selection.State);	
	EndIf;

	Return StateInfo3;

EndFunction

// Called to record the original states of print forms to the register after printing the form.
//
//	Parameters:
//  PrintObjects - ValueList - List of references to print objects.
//  PrintList - ValueList - List with template names and print form presentations.
//  Written1 - Boolean - Indicates that the document state is written to the register.
//
Procedure WriteOriginalsStatesAfterPrint(PrintObjects, PrintList, Written1 = False) Export

	If GetFunctionalOption("UseSourceDocumentsOriginalsRecording") And Not Users.IsExternalUserSession() Then
		WhenDeterminingTheListOfPrintedForms(PrintObjects, PrintList);
		If PrintList.Count() = 0 Then
			Return;
		EndIf;
		WriteDocumentOriginalsStatesAfterPrintForm(PrintObjects, PrintList, Written1);
	EndIf;

EndProcedure

// Updates commands that set the original state on the form.
//
// Parameters:
//  Form - ClientApplicationForm - a document list form.
//  List - FormTable - Main form list. It is set to "Undefined" if the procedure is invoked for the document form.
//
Procedure UpdateOriginalStateCommands(Form, List = Undefined) Export

	OriginalsStates = UsedStates();
	
	OutputOriginalStateCommandsToForm(Form, List, OriginalsStates);
	
	If Not List = Undefined Then
		FillOriginalStatesChoiceList(Form, OriginalsStates); 
	EndIf;

EndProcedure

// Sets conditional formatting for attachable items in the list.
//
// Parameters:
//  Form - ClientApplicationForm - a document list form.
//  List - FormTable - the main form list.
//
Procedure SetConditionalAppearanceInListForm(Form, List) Export

	AppearanceItem = Form.ConditionalAppearance.Items.Add();

	FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField(List.Name+".SourceDocumentOriginalState");
	FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
	FilterElement.Use = True;

	AppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<Không xác định>';
															|ru = '<Неизвестно>';
															|en = '<Unknown>'; fa = '<Unknown>';
															|it = '<Sconosciuto>';
															|pl = '<Unknown>';
															|tr = '<Bilinmiyor>'"));
	AppearanceItem.Appearance.SetParameterValue("TextColor",  StyleColors.InaccessibleCellTextColor);
	AppearanceItem.Use = True;
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("SourceDocumentOriginalState");
	AppearanceField.Use = True;
	
	AppearanceItem = Form.ConditionalAppearance.Items.Add();

	FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField(List.Name+".SourceDocumentOriginalState");
	FilterElement.ComparisonType = DataCompositionComparisonType.Filled;
	FilterElement.Use = True;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	AppearanceItem.Use = True;

	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("SourceDocumentOriginalState");
	AppearanceField.Use = True;

EndProcedure

// Adds a role that changes the original state to the profile details of 1C-supplied access groups. 
//
// Parameters:
//  ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription
//
Procedure SupplementProfileWithRoleForDocumentsOriginalsStatesChange(ProfileDetails) Export

	ProfileDetails.Roles.Add("SourceDocumentsOriginalsStatesChange");

EndProcedure

// Adds a role that configures the list of original states to the profile details of 1C-supplied access groups.
//
// Parameters:
//  ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription.
//
Procedure SupplementProfileWithRoleForDocumentsOriginalsStatesSetup(ProfileDetails) Export

	ProfileDetails.Roles.Add("AddEditSourceDocumentsOriginalsStates");

EndProcedure

// Adds a role that reads the original state to the profile details of 1C-supplied access groups.
//
// Parameters:
//  ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription.
//
Procedure SupplementProfileWithRoleForDocumentsOriginalsStatesReading(ProfileDetails) Export

	ProfileDetails.Roles.Add("ReadSourceDocumentsOriginalsStates");

EndProcedure

// Returns an array of source document states.
//
//	Returns:
//  Array of CatalogRef.SourceDocumentsOriginalsStates - all possible original states, including
//    the hidden "Not all originals" state.
//
Function AllStates() Export
	
	Query = New Query;
	Query.Text ="SELECT ALLOWED
	              |	SourceDocumentsOriginalsStates.Ref AS State
	              |FROM
	              |	Catalog.SourceDocumentsOriginalsStates AS SourceDocumentsOriginalsStates
	              |WHERE
	              |	NOT SourceDocumentsOriginalsStates.DeletionMark
	              |
	              |ORDER BY
	              |	SourceDocumentsOriginalsStates.AddlOrderingAttribute" ;

	Selection = Query.Execute();

	Return Selection.Unload().UnloadColumn("State");

EndFunction

// Displays attachable commands in the form. Called without implementing the "Attachable commands" subsystem.
//
// Parameters:
//  Form - ClientApplicationForm - a document list form.
//  List - FormTable - Main form list. It is set to "Undefined" if the procedure is invoked for the document form.
//  OriginalsStates - ValueTable - original states available to users and used when changing
//                                          the original state:
//              * Description	- String - Description of the original state.
//              * Ref		- CatalogRef.SourceDocumentsOriginalsStates - a reference to an item of the SourceDocumentsOriginalsStates catalog.
//
Procedure OutputOriginalStateCommandsToForm(Form, List, OriginalsStates) Export
	
	// Check and create a submenu and button list on the list command bar.
	Items = Form.Items;
	Parent = ?(TypeOf(List) = Type("FormTable"), List.CommandBar, Form.CommandBar);
	Picture = ?(TypeOf(List) = Type("FormTable"), PictureLib.SetSourceDocumentOriginalState,
		PictureLib.SourceDocumentOriginalStateOriginalNotReceived);

	If Items.Find("SetConfigureOriginalStateSubmenu") = Undefined Then
		SetConfigureOriginalStateSubmenu = Items.Add("SetConfigureOriginalStateSubmenu", Type("FormGroup"), Parent);
		SetConfigureOriginalStateSubmenu.Type = FormGroupType.Popup;
		SetConfigureOriginalStateSubmenu.Representation = ButtonRepresentation.Picture; 
		SetConfigureOriginalStateSubmenu.Picture  = Picture;
		SetConfigureOriginalStateSubmenu.Title = NStr("vi = 'Đặt trạng thái bản chính';
														|ru = 'Установить состояние оригинала';
														|en = 'Set original state'; fa = 'تعیین وضعیت اصل';
														|it = 'Impostare lo stato dell''originale';
														|pl = 'Ustaw status oryginała';
														|tr = 'Aslın durumunu belirle'");
		SetConfigureOriginalStateSubmenu.ToolTip = NStr("vi = 'Menu con của các lệnh dùng để thiết lập và thay đổi trạng thái của bản gốc chứng từ.';
														|ru = 'Подменю команд для установки и изменения состояния оригиналов первичных документов.';
														|en = 'Use these commands to set and change states of source document originals.'; fa = 'از این فرمان‌ها برای تعیین و تغییر وضعیت‌های اصل اسناد مبدأ استفاده کنید.';
														|it = 'Подменю команд для установки и изменения состояния оригиналов первичных документов.';
														|pl = 'Use these commands to set and change states of source document originals.';
														|tr = 'Birincil belgelerin asıllarının durumunu yapılandırmak ve değiştirmek için alt menü komutları.'");
	EndIf;
	SetConfigureOriginalStateSubmenu = Items.Find("SetConfigureOriginalStateSubmenu");
	
	If Items.Find("SetOriginalStateGroup") = Undefined Then
		SetOriginalStateGroup = Items.Add("SetOriginalStateGroup", Type("FormGroup"),
			SetConfigureOriginalStateSubmenu);
		SetOriginalStateGroup.Type = FormGroupType.ButtonGroup;
	EndIf;
	SetOriginalStateGroup = Items.Find("SetOriginalStateGroup");

	If Items.Find("ConfigureOriginalStatesGroup") = Undefined Then
		ConfigureOriginalStatesGroup = Items.Add("ConfigureOriginalStatesGroup", Type("FormGroup"),
			SetConfigureOriginalStateSubmenu);
		ConfigureOriginalStatesGroup.Type = FormGroupType.ButtonGroup;
	EndIf;
	ConfigureOriginalStatesGroup = Items.Find("ConfigureOriginalStatesGroup");	
	
	If Items.Find("SetOriginalReceivedGroup") = Undefined And Not TypeOf(List) = Type("Boolean") Then
		SetOriginalReceivedGroup =  Items.Add("SetOriginalReceivedGroup", Type("FormGroup"), 
			List.CommandBar); 
		SetOriginalReceivedGroup.Type = FormGroupType.ButtonGroup;
		SetOriginalReceivedGroup.ToolTip = NStr("vi = 'Thiết lập trạng thái cuối của bản gốc chứng từ ban đầu ""Đã nhận bản gốc"".';
												|ru = 'Установить конечное состояние оригинала первичного документа ""Оригинал получен"".';
												|en = 'Set the final ""Original received"" state of the source document original.'; fa = 'Set the final ""Original received"" state of the source document original.';
												|it = 'Установить конечное состояние оригинала первичного документа ""Оригинал получен"".';
												|pl = 'Set the final ""Original received"" state of the source document original.';
												|tr = 'Birincil belge aslının son durumunu ""Aslı alındı"" olarak yapılandır.'");
	EndIf;
	SetOriginalReceivedGroup = Items.Find("SetOriginalReceivedGroup");
	
	CommandsNamesArray = New Array;
	For Each Command In SetOriginalStateGroup.ChildItems Do
		CommandsNamesArray.Add(Command.CommandName);
	EndDo;
	
	For Each Command In CommandsNamesArray Do
		FoundCommand = Form.Commands.Find(Command);
		FoundButton = Form.Items.Find(Command);

		If Not FoundCommand = Undefined Then
			Form.Commands.Delete(FoundCommand);
			Form.Items.Delete(FoundButton);
		EndIf;
	EndDo;
	
	For Each State In OriginalsStates Do
		CommandName = "Command" + StrReplace(State.Ref.UUID(),"-","_");
		ButtonName = State.Description;

		If Form.Commands.Find(CommandName) = Undefined Then
			Command = Form.Commands.Add(CommandName);
			Command.Action = "Attachable_SetOriginalState";

			// Command bar buttons.
			SetStateButton = Form.Items.Add(CommandName, Type("FormButton"), SetOriginalStateGroup);
			SetStateButton.Title = ButtonName;
			SetStateButton.CommandName = CommandName;

			// Set pictures.
			If State.Ref = Catalogs.SourceDocumentsOriginalsStates.OriginalReceived Then
				SetStateButton.Picture = PictureLib.SourceDocumentOriginalStateOriginalReceived;
			ElsIf State.Ref = Catalogs.SourceDocumentsOriginalsStates.FormPrinted Then
				SetStateButton.Picture = PictureLib.SourceDocumentOriginalStateOriginalNotReceived;
			EndIf;
			
		EndIf;
	EndDo;
	
	// Adds a button for identifying the original state by print forms.
	If TypeOf(List) = Type("Boolean") Then
		CommandName = "ClarifyByPrintForms";
		ButtonName = NStr("vi = 'Làm rõ theo mẫu in...';
							|ru = 'Уточнить по печатным формам...';
							|en = 'Specify for print forms…'; fa = 'Specify for print forms…';
							|it = 'Stabilire in base ai moduli stampati...';
							|pl = 'Uściślij wg formularzy wydruku...';
							|tr = 'Yazdırma formlarına göre netleştir...'");

		If Form.Commands.Find(CommandName) = Undefined Then
			FormCommand  = Form.Commands.Add(CommandName);
			FormCommand.Action = "Attachable_SetOriginalState";
			FormCommand.Title = ButtonName;
			
			ConfigureStatesButton = Form.Items.Add(CommandName, Type("FormButton"),SetOriginalStateGroup);
			ConfigureStatesButton.Title = ButtonName;
			ConfigureStatesButton.CommandName = CommandName;
			ConfigureStatesButton.Picture = PictureLib.SetSourceDocumentOriginalStateByPrintForms;
		EndIf; 
		
	EndIf;
	
	// Adds a state settings navigation button to the command bar submenu of the "Set state" list.
	If AccessRight("InteractiveInsert", Metadata.Catalogs.SourceDocumentsOriginalsStates) Then
		CommandName = "StatesSetup";
		ButtonName = NStr("vi = 'Tùy chỉnh...';
							|ru = 'Настроить...';
							|en = 'Configure…'; fa = 'پیکربندی…';
							|it = 'Imposta...';
							|pl = 'Dostosuj...';
							|tr = 'Özelleştir...'");

		If Form.Commands.Find(CommandName) = Undefined Then
			FormCommand  = Form.Commands.Add(CommandName);
			FormCommand.Action = "Attachable_SetOriginalState";
			FormCommand.Title = ButtonName;
			
			ConfigureStatesButton = Form.Items.Add(CommandName, Type("FormButton"),ConfigureOriginalStatesGroup);
			ConfigureStatesButton.Title = ButtonName;
			ConfigureStatesButton.CommandName = CommandName;
			ConfigureStatesButton.Picture = PictureLib.ConfigureSourceDocumentOriginalStates;
		EndIf; 
		
	EndIf;

	// Adds the "Set original received" button to the list command bar. 
	CommandName = "SettingStateOriginalReceived";
	If Form.Commands.Find(CommandName) = Undefined And Not TypeOf(List) = Type("Boolean") Then
		FormCommand  = Form.Commands.Add(CommandName);
		FormCommand.Action = "Attachable_SetOriginalState";
		FormCommand.Title = NStr("vi = 'Đặt ""Đã nhận bản gốc""';
								|ru = 'Установить ""Оригинал получен""';
								|en = 'Set ""Original received""'; fa = 'Set ""Original received""';
								|it = 'Impostare ""Originale ricevuto""';
								|pl = 'Ustaw ""Otrzymano oryginał""';
								|tr = '""Aslı alındı"" belirle'");
		FormCommand.ToolTip = NStr("vi = 'Đặt ""Đã nhận bản gốc""';
									|ru = 'Установить ""Оригинал получен""';
									|en = 'Set ""Original received""'; fa = 'Set ""Original received""';
									|it = 'Impostare ""Originale ricevuto""';
									|pl = 'Ustaw ""Otrzymano oryginał""';
									|tr = '""Aslı alındı"" belirle'");
		
		NewButton = Form.Items.Add("Button" + CommandName , Type("FormButton"), SetOriginalReceivedGroup);
		NewButton.Picture = PictureLib.SourceDocumentOriginalStateOriginalReceived;
		NewButton.CommandName = CommandName;
	EndIf;

EndProcedure

// Returns the presentation of the hyperlink of a source document state by Ref.
//
//	Parameters:
//   Document - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - Reference to the document for which the presentation of
//																			 the state hyperlink is to be received.
//  Returns:
//   String - Presentation of the original state hyperlink.
//
Function StateHyperlinkPresentation(Document) Export
	
	ReferencesArrray = CommonClientServer.ValueInArray(Document);
	UnpostedDocuments = Common.CheckDocumentsPosting(ReferencesArrray);
	If UnpostedDocuments.Count() > 0 Then
		CurrentOriginalState = NStr("vi = '<Trạng thái bản gốc không xác định>';
									|ru = '<Состояние оригинала неизвестно>';
									|en = '<Original state is unknown>'; fa = '<Original state is unknown>';
									|it = '<Stato dell''originale sconosciuto>';
									|pl = '<Status oryginału nie jest znany>';
									|tr = '<Aslın durumu bilinmiyor>'");
		Return CurrentOriginalState;
	EndIf;
	
	CurrentOriginalState = OriginalStateInfoByRef(Document);
	If CurrentOriginalState.Count() = 0 Then
		CurrentOriginalState=NStr("vi = '<Trạng thái bản gốc không xác định>';
									|ru = '<Состояние оригинала неизвестно>';
									|en = '<Original state is unknown>'; fa = '<Original state is unknown>';
									|it = '<Stato dell''originale sconosciuto>';
									|pl = '<Status oryginału nie jest znany>';
									|tr = '<Aslın durumu bilinmiyor>'");
	Else
		CurrentOriginalState = CurrentOriginalState.SourceDocumentOriginalState;
	EndIf;
	
	Return CurrentOriginalState;
	
EndFunction

// Sets states to print forms' source documents. Invoked after printing a form.
//
// Parameters:
//   PrintObjects - ValueList - Document list.
//   PrintForms - ValueList - The description of descriptions and the presentation of print forms.
//   Written1 - Boolean - Output parameter. Indicates that the document status is written.
//
Procedure WriteDocumentOriginalsStatesAfterPrintForm(PrintObjects, PrintForms, Written1 = False) Export
	
	SSLSubsystemsIntegration.BeforeWriteOriginalStatesAfterPrint(PrintObjects, PrintForms);
	SourceDocumentsOriginalsRecordingOverridable.BeforeWriteOriginalStatesAfterPrint(PrintObjects, PrintForms);
	
	State = PredefinedValue("Catalog.SourceDocumentsOriginalsStates.FormPrinted");
	If Not ValueIsFilled(PrintObjects) Then 
		Return;
	EndIf;
	
	Block = New DataLock();

	BeginTransaction();
	Try
		
		For Each Document In PrintObjects Do
			If IsAccountingObject(Document.Value) Then 
				LockItem = Block.Add("InformationRegister.SourceDocumentsOriginalsStates");
				LockItem.SetValue("Owner", Document.Value); 
			EndIf;
		EndDo;
		Block.Lock();
		
		For Each Document In PrintObjects Do
			If IsAccountingObject(Document.Value) Then 
				TS = TableOfEmployees(Document.Value);
				If TS <> "" Then
					For Each Employee In Document.Value[TS] Do
						For Each Form In PrintForms Do 
							WriteDocumentOriginalStateByPrintForms(Document.Value, 
								Form.Value, Form.Presentation, State, False, Employee.Employee);
						EndDo;
					EndDo;
				Else
					For Each Form In PrintForms Do
						WriteDocumentOriginalStateByPrintForms(Document.Value, Form.Value,
							Form.Presentation, State, False);
					EndDo;
				EndIf;
				WriteCommonDocumentOriginalState(Document.Value, State);
				Written1 = True;
			EndIf;
		EndDo;
		
		CommitTransaction();
		
	Except	
		
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Sets a state to a print form's source document. Invoked after printing a form.
//
// Parameters:
//   Document - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - Document.
//   PrintForm - String - Name of a print form template.
//   Presentation - String - Print form description.
//   State - CatalogRef.SourceDocumentsOriginalsStates - State of the print form's source document.
//   FromOutside - Boolean - Indicates whether the form belongs to 1C:Enterprise.
//   Employee - CatalogRef - Employee (if the source document contains information about employees).
//
Procedure WriteDocumentOriginalStateByPrintForms(Document, PrintForm, Presentation, State, 
	FromOutside, Employee = Undefined) Export
	
	SetPrivilegedMode(True);
	
	OriginalStateRecord = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordManager();
	OriginalStateRecord.Owner = Document;
	OriginalStateRecord.SourceDocument = PrintForm;
	If ValueIsFilled(Employee) Then
		LastFirstName = PersonsClientServer.InitialsAndLastName(Employee.Description);
		EmployeeView = StrFind(Presentation, LastFirstName);
		If EmployeeView = 0 Then
			OriginalStateRecord.SourceDocumentPresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 %2';
					|ru = '%1 %2';
					|en = '%1 %2'; fa = '%1 %2';
					|it = '%1 %2';
					|pl = '%1 %2';
					|tr = '%1 %2'"), Presentation, LastFirstName);
		Else
			OriginalStateRecord.SourceDocumentPresentation = Presentation;
		EndIf;
	Else
		OriginalStateRecord.SourceDocumentPresentation = Presentation;
	EndIf; 
	If TypeOf(State) = Type("String") Then
		OriginalStateRecord.State = Catalogs.SourceDocumentsOriginalsStates.FindByDescription(State);
	Else
		OriginalStateRecord.State = State;
	EndIf;
	OriginalStateRecord.ChangeAuthor = Users.CurrentUser();
	OriginalStateRecord.OverallState = False;
	OriginalStateRecord.ExternalForm = FromOutside;
	OriginalStateRecord.LastChangeDate = CurrentSessionDate();
	OriginalStateRecord.Employee = Employee;
	OriginalStateRecord.Write();

EndProcedure

// Saves the aggregated state of a source document.
//
// Parameters:
//   Document - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - Document.
//   State - CatalogRef.SourceDocumentsOriginalsStates - Original state.
//
Procedure WriteCommonDocumentOriginalState(Document, State) Export
	
	If TypeOf(State) = Type("String") Then
		OriginalState = Catalogs.SourceDocumentsOriginalsStates.FindByDescription(State);
	Else
		OriginalState = State;
	EndIf;

	SetPrivilegedMode(True);
		
	OriginalStateRecord = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordManager();
	OriginalStateRecord.Owner = Document;
	OriginalStateRecord.SourceDocument = "";
		
	CheckOriginalStateRecord = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordSet();
	CheckOriginalStateRecord.Filter.Owner.Set(Document);
	CheckOriginalStateRecord.Filter.OverallState.Set(False);
	CheckOriginalStateRecord.Read();
	If CheckOriginalStateRecord.Count() Then
		FormsStateSame = True;
		For Each Record In CheckOriginalStateRecord Do
			If Record.ChangeAuthor <> Users.CurrentUser() Then
				OriginalStateRecord.ChangeAuthor = Undefined;
			Else
				OriginalStateRecord.ChangeAuthor = Users.CurrentUser();
			EndIf;
			If Record.State = OriginalState Then
				Continue;
			EndIf;
			FormsStateSame = False;
		EndDo;
		If FormsStateSame Then
			OriginalStateRecord.State = OriginalState;
		Else
			OriginalStateRecord.State = Catalogs.SourceDocumentsOriginalsStates.OriginalsNotAll;
		EndIf;
	Else
		OriginalStateRecord.ChangeAuthor = Users.CurrentUser();
		OriginalStateRecord.State = OriginalState;
	EndIf;
		
	OriginalStateRecord.OverallState = True;
	OriginalStateRecord.LastChangeDate = CurrentSessionDate();
	OriginalStateRecord.Write();
	
	SSLSubsystemsIntegration.OnChangeAggregatedOriginalState(Document, OriginalState);
	SourceDocumentsOriginalsRecordingOverridable.OnChangeAggregatedOriginalState(Document, OriginalState);
	
EndProcedure

#EndRegion

#Region Internal

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.3.142";
	Handler.InitialFilling = True;
	Handler.Procedure = "SourceDocumentsOriginalsRecording.WriteSourceDocumentOriginalState";
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.4.137"; 
	Handler.Id = New UUID("35320bc5-3ec6-4036-9253-ee5c507531e3");
	Handler.Procedure = "Catalogs.SourceDocumentsOriginalsStates.ProcessDataForMigrationToNewVersion";
	Handler.Comment = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Điền lại mục tin dịch vụ %1 để khắc phục lỗi có thể xảy ra.';
			|ru = 'Перезаполнение служебного реквизита %1 для устранения вероятного сбоя порядка.';
			|en = 'Repopulate internal attribute %1 to prevent misordering.'; fa = 'Repopulate internal attribute %1 to prevent misordering.';
			|it = 'Ricompilazione del requisito di servizio %1 per eliminare eventuali errori di ordine.';
			|pl = 'Ponowne wypełnienie atrybutu serwisowego ""%1"" do usunięcia możliwej awarii porządku.';
			|tr = 'Olası bir düzen bozulmasını ortadan kaldırmak için %1 servis özniteliğini yeniden doldur.'"),
		"AddlOrderingAttribute");
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "Catalogs.SourceDocumentsOriginalsStates.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToRead      = "Catalog.SourceDocumentsOriginalsStates";
	Handler.ObjectsToChange    = "Catalog.SourceDocumentsOriginalsStates";
	Handler.ObjectsToLock   = "Catalog.SourceDocumentsOriginalsStates";
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
		Priority = Handler.ExecutionPriorities.Add();
		Priority.Procedure = "NationalLanguageSupportServer.ProcessDataForMigrationToNewVersion";
		Priority.Order = "Before";
	EndIf;
	
EndProcedure

// See also "InfobaseUpdateOverridable.OnDefineSettings".
//
// Parameters:
//  Objects - Array of MetadataObject
//
Procedure OnDefineObjectsWithInitialFilling(Objects) Export

	Objects.Add(Metadata.Catalogs.SourceDocumentsOriginalsStates);

EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport.
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export

	TableRow = CatalogsToImport.Find(Metadata.Catalogs.SourceDocumentsOriginalsStates.FullName(), 
		"FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;

EndProcedure

// See AttachableCommandsOverridable.OnDefineAttachableCommandsKinds.
Procedure OnDefineAttachableCommandsKinds(AttachableCommandsKinds) Export
	
	If Not GetFunctionalOption("UseSourceDocumentsOriginalsRecording")Then
		Return;
	EndIf;

	Kind = AttachableCommandsKinds.Add();
	Kind.Name         = "SettingOriginalState";
	Kind.SubmenuName  = "SetConfigureOriginalStateSubmenu";
	Kind.Title   = NStr("vi = 'Đặt trạng thái bản gốc';
						|ru = 'Установить состояние оригинала';
						|en = 'Set original state'; fa = 'تعیین وضعیت اصل';
						|it = 'Impostare lo stato dell''originale';
						|pl = 'Ustaw status oryginała';
						|tr = 'Aslın durumunu belirle'");
	Kind.Picture    = PictureLib.SetSourceDocumentOriginalState;
	Kind.Representation = ButtonRepresentation.Picture;
	
	Kind = AttachableCommandsKinds.Add();
	Kind.Name         = "SettingStateOriginalReceived";
	Kind.SubmenuName  = "SetStateOriginalReceived";
	Kind.Title   = NStr("vi = 'Đặt trạng thái ""Đã nhận bản gốc""';
						|ru = 'Установить состояние ""Оригинал получен""';
						|en = 'Set ""Original received"" state'; fa = 'Set ""Original received"" state';
						|it = 'Impostare stato ""Originale ricevuto""';
						|pl = 'Ustaw status ""Otrzymano oryginał""';
						|tr = '""Aslı alındı"" durumunu belirle'");
	Kind.Picture    = PictureLib.SourceDocumentOriginalStateOriginalReceived;	
	Kind.Representation = ButtonRepresentation.Picture;

EndProcedure

// See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject.
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export
	
	If Not RightsToChangeState() Then
		Return;
	EndIf;

	ObjectsWithSourceDocumentsOriginalsAccounting = New Array;
	
	Settings = SubsystemSettings();
	
	SSLSubsystemsIntegration.OnDefineObjectsWithOriginalsAccountingCommands(ObjectsWithSourceDocumentsOriginalsAccounting);
	SourceDocumentsOriginalsRecordingOverridable.OnDefineObjectsWithOriginalsAccountingCommands(ObjectsWithSourceDocumentsOriginalsAccounting);
	
	NeedOutputCommands = False;
	
	For Each Object In ObjectsWithSourceDocumentsOriginalsAccounting Do
		If StrFind(FormSettings.FormName, Object) Then
			NeedOutputCommands = True;
			Break;
		EndIf;
	EndDo;

	If Not NeedOutputCommands And Not (FormSettings.IsObjectForm And Settings.ShouldDisplayButtonsOnDocumentForm) Then
		Return;
	EndIf;
	
	ObjectsWithSourceDocumentsOriginalsAccounting.Clear();
	
	For Each Type In Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type.Types() Do
		If Type = Type("CatalogRef.MetadataObjectIDs") Then
			Continue;
		EndIf;
		MetadataObject = Metadata.FindByType(Type);
		ObjectsWithSourceDocumentsOriginalsAccounting.Add(MetadataObject.FullName());
	EndDo;
	
	For Each Source In Sources.Rows Do
		If ObjectsWithSourceDocumentsOriginalsAccounting.Find(Source.FullName) <> Undefined Then
			NeedOutputCommands = True;
			Break;
		EndIf;
	EndDo;
	If Not NeedOutputCommands Then
		Return;
	EndIf;

	OriginalsStates = UsedStates();
	
	Order = 0;
	
	// Original state commands.
	For Each State In OriginalsStates Do
		Command = Commands.Add();
		Command.Kind = "SettingOriginalState";
		Command.Presentation = State.Description;
		Command.Order = Order + 1; 
		// Set pictures.
		If State.Ref = Catalogs.SourceDocumentsOriginalsStates.OriginalReceived Then
			Command.Picture = PictureLib.SourceDocumentOriginalStateOriginalReceived;
		ElsIf State.Ref = Catalogs.SourceDocumentsOriginalsStates.FormPrinted Then
			Command.Picture = PictureLib.SourceDocumentOriginalStateOriginalNotReceived;
		EndIf;		
		Command.ParameterType = Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type;
		Command.WriteMode = "Post";
		Command.FunctionalOptions = "UseSourceDocumentsOriginalsRecording";
		Command.Handler = "SourceDocumentsOriginalsRecordingClient.Attachable_SetOriginalState";
		Command.AdditionalParameters.Insert("RefToState", State.Ref); 
		
		Order = Order + 1;
	EndDo;
	
	// Command for clarifying the original state by print forms	
	Command = Commands.Add();
	Command.Kind = "SettingOriginalState";
	Command.Order = Order; 
	Command.Id = "ClarifyByPrintForms";
	Command.Presentation = NStr("vi = 'Làm rõ theo mẫu in...';
								|ru = 'Уточнить по печатным формам...';
								|en = 'Specify for print forms…'; fa = 'Specify for print forms…';
								|it = 'Stabilire in base ai moduli stampati...';
								|pl = 'Uściślij wg formularzy wydruku...';
								|tr = 'Yazdırma formlarına göre netleştir...'");
	Command.Picture = PictureLib.SetSourceDocumentOriginalStateByPrintForms;
	Command.Purpose = "ForObject";
	Command.ParameterType = Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type;
	Command.WriteMode = "Post";
	Command.FunctionalOptions = "UseSourceDocumentsOriginalsRecording";
	Command.Handler = "SourceDocumentsOriginalsRecordingClient.Attachable_SetOriginalState";
		
	// A command for navigating to the state settings in the "Set state" submenu of the list command bar.
	// Applicable if the user is assigned the required role.
	If AccessRight("InteractiveInsert", Metadata.Catalogs.SourceDocumentsOriginalsStates) Then
		Command = Commands.Add();
		Command.Kind = "SettingOriginalState";
		Command.Id = "StatesSetup";
		Command.Presentation = NStr("vi = 'Tùy chỉnh...';
									|ru = 'Настроить...';
									|en = 'Configure…'; fa = 'پیکربندی…';
									|it = 'Imposta...';
									|pl = 'Dostosuj...';
									|tr = 'Özelleştir...'");
		Command.Importance = "SeeAlso";
		Command.Picture = PictureLib.ConfigureSourceDocumentOriginalStates;
		Command.ParameterType = Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type;
		Command.WriteMode = "NotWrite";
		Command.FunctionalOptions = "UseSourceDocumentsOriginalsRecording";
		Command.Handler = "SourceDocumentsOriginalsRecordingClient.Attachable_SetOriginalState";	
	EndIf;
	
	Description = String(Catalogs.SourceDocumentsOriginalsStates.OriginalReceived);

	// Command "Set original received" on the list command bar. 
	Command = Commands.Add();
	Command.Kind = "SettingStateOriginalReceived";
	Command.Id = "SettingStateOriginalReceived";
	Command.Presentation = StringFunctionsClientServer.InsertParametersIntoString(NStr("vi = 'Đặt trạng thái ""[Description]""';
																						|ru = 'Установить состояние ""[Description]""';
																						|en = 'Set the ""[Description]"" state'; fa = 'Set the ""[Description]"" state';
																						|it = 'Impostare stato ""[Description]""';
																						|pl = 'Ustaw status ""[Description]""';
																						|tr = '""[Description]"" durumunu belirle'"),
																							New Structure("Description",Description));
	Command.ButtonRepresentation = ButtonRepresentation.Picture;
	Command.Picture = PictureLib.SourceDocumentOriginalStateOriginalReceived;
	Command.ParameterType = Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type;
	Command.Purpose = "ForList";
	Command.WriteMode = "Post";
	Command.FunctionalOptions = "UseSourceDocumentsOriginalsRecording";
	Command.Handler = "SourceDocumentsOriginalsRecordingClient.Attachable_SetOriginalState";	
	Command.AdditionalParameters.Insert("RefToState", Catalogs.SourceDocumentsOriginalsStates.OriginalReceived);

EndProcedure

// See CommonOverridable.OnAddClientParameters.
Procedure OnAddClientParameters(Parameters) Export
	
	If Not GetFunctionalOption("UseSourceDocumentsOriginalsRecording") 
		Or Not AccessRight("Read", Metadata.InformationRegisters.SourceDocumentsOriginalsStates) Then
		Return;
	EndIf;	
	
	SubsystemSettings = SubsystemSettings();
	
	Parameters.Insert("SourceDocumentsOriginalsRecording", New FixedStructure(
		SubsystemSettings));
	
EndProcedure

Procedure BeforeItemMoved(ItemToMove, AdjacentElement, Direction, ErrorText, 
	StandardProcessing) Export
	
	If TypeOf(ItemToMove) <> Type("CatalogRef.SourceDocumentsOriginalsStates") Then
		Return;
	EndIf;
	
	ItemFormPrinted = PredefinedValue("Catalog.SourceDocumentsOriginalsStates.FormPrinted");
	ItemOriginalReceived = PredefinedValue("Catalog.SourceDocumentsOriginalsStates.OriginalReceived");
	
	MovingDown = Direction = ItemOrderSetup.ItemMovementDirectionDown();
	MovingUp = Direction = ItemOrderSetup.ItemMovementDirectionUp();
	
	If AdjacentElement = ItemFormPrinted And MovingUp
		Or (ItemToMove = ItemFormPrinted And MovingDown) Then
		StandardProcessing = False;
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trạng thái ""%1"" là trạng thái bắt đầu, không xem xét sắp xếp các trạng thái khác trước nó.';
				|ru = 'Состояние ""%1"" является начальным, размещение перед ним других состояний не предусмотрено.';
				|en = 'The ""%1"" state is the initial state. No other states can be set before it.'; fa = 'The ""%1"" state is the initial state. No other states can be set before it.';
				|it = 'Состояние ""%1"" является начальным, размещение перед ним других состояний не предусмотрено.';
				|pl = 'The ""%1"" state is the initial state. No other states can be set before it.';
				|tr = '""%1"" durumu başlangıç durumudur, bunun önüne başka herhangi durum yerleştirilemez.'"),
			ItemFormPrinted);
	EndIf;
	
	If AdjacentElement = ItemOriginalReceived And MovingDown 
		Or (ItemToMove = ItemOriginalReceived And MovingUp) Then
		StandardProcessing = False;
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trạng thái ""%1"" là trạng thái cuối cùng, không xem xét sắp xếp các trạng thái khác sau nó.';
				|ru = 'Состояние ""%1"" является конечным, размещение после него других состояний не предусмотрено.';
				|en = 'The ""%1"" state is the final state. No other states can be set after it.'; fa = 'The ""%1"" state is the final state. No other states can be set after it.';
				|it = 'Состояние ""%1"" является конечным, размещение после него других состояний не предусмотрено.';
				|pl = 'The ""%1"" state is the final state. No other states can be set after it.';
				|tr = '""%1"" durumu kapanış durumudur, bunun önüne başka herhangi durum yerleştirilemez.'"),
			ItemOriginalReceived);
	EndIf;
	
EndProcedure

Function SubsystemSettings() Export
	
	Settings = New Structure;
	Settings.Insert("ShouldDisplayButtonsOnDocumentForm", False);
	Settings.Insert("ShouldDisplayHintInStatesChangeForm", True);
	Settings.Insert("ShouldOpenDropDownMenuFromHyperlink", True);
	
	SSLSubsystemsIntegration.OnDefineSettingsOfOriginalsRecording(Settings);
	SourceDocumentsOriginalsRecordingOverridable.OnDefineSettings(Settings);
	
	Return Settings;
	
EndFunction

#EndRegion

#Region Private

Function RightsToChangeState()
	
	Return AccessRight("Edit", Metadata.InformationRegisters.SourceDocumentsOriginalsStates);

EndFunction

Procedure ConfigureHyperlinkOnDocumentForm(Form, Placement)
		
	Attributes = New Array;
	Attributes.Add(New FormAttribute("OriginalStatesChoiceList", New TypeDescription("ValueList")));
	
	Form.ChangeAttributes(Attributes);

	OriginalsStates = UsedStates();
	
	FillOriginalStatesChoiceList(Form, OriginalsStates);
	
	If Placement = Undefined Then
		Parent = Form;
	Else
		Parent = Placement;
	EndIf;
	
	OriginalStateDecoration = Form.Items.Add("OriginalStateDecoration", Type("FormDecoration"), Parent);
	OriginalStateDecoration.Type = FormDecorationType.Label;
	OriginalStateDecoration.Hyperlink = True;
	If Placement = Undefined Then
		OriginalStateDecoration.HorizontalAlignInGroup = ItemHorizontalLocation.Right;
	EndIf;
	OriginalStateDecoration.SetAction("Click", "Attachable_OriginalStateDecorationClick");

	If ValueIsFilled(Form.Object.Ref) Then
		CurrentOriginalState = OriginalStateInfoByRef(Form.Object.Ref);
		If CurrentOriginalState.Count() = 0 Then
			CurrentOriginalState=NStr("vi = '<Trạng thái bản gốc không xác định>';
										|ru = '<Состояние оригинала неизвестно>';
										|en = '<Original state is unknown>'; fa = '<Original state is unknown>';
										|it = '<Stato dell''originale sconosciuto>';
										|pl = '<Status oryginału nie jest znany>';
										|tr = '<Aslın durumu bilinmiyor>'");
			OriginalStateDecoration.TextColor = StyleColors.InaccessibleCellTextColor;
		Else
			CurrentOriginalState = CurrentOriginalState.SourceDocumentOriginalState;
		EndIf;
	Else
		CurrentOriginalState=NStr("vi = '<Trạng thái bản gốc không xác định>';
									|ru = '<Состояние оригинала неизвестно>';
									|en = '<Original state is unknown>'; fa = '<Original state is unknown>';
									|it = '<Stato dell''originale sconosciuto>';
									|pl = '<Status oryginału nie jest znany>';
									|tr = '<Aslın durumu bilinmiyor>'");
		OriginalStateDecoration.TextColor = StyleColors.InaccessibleCellTextColor;
	EndIf;

	OriginalStateDecoration.Title = CurrentOriginalState;

EndProcedure

Procedure ConfigureButtonsOnDocumentForm(Form)
	
	SubmenuOriginalState = Form.Items.Find("SetConfigureOriginalStateSubmenu");
	If SubmenuOriginalState = Undefined Then
		Return;
	EndIf;
	
	SubmenuOriginalState.Representation = ButtonRepresentation.Picture;
	SubmenuOriginalState.Picture = PictureLib.SourceDocumentOriginalStateOriginalNotReceived;	 
		
	If ValueIsFilled(Form.Object.Ref) Then
		InformationRecords = OriginalStateInfoByRef(Form.Object.Ref);
		If Not InformationRecords.Count() = 0 Then 
			CurrentOriginalState = InformationRecords.SourceDocumentOriginalState;
			Picture = ?(CurrentOriginalState = Catalogs.SourceDocumentsOriginalsStates.OriginalReceived,
			PictureLib.SourceDocumentOriginalStateOriginalReceived,
			PictureLib.SourceDocumentOriginalStateOriginalNotReceived);
			SubmenuOriginalState.Representation = ButtonRepresentation.PictureAndText;
			SubmenuOriginalState.Title = CurrentOriginalState;  
			SubmenuOriginalState.Picture = Picture;
		EndIf;
	EndIf;

EndProcedure

//	Parameters:
//  WritingObjects - Array of Structure - Information on the original state being changed:
//                 * OverallState    - Boolean - "True" if the current state is aggregated.
//                 * Ref 		   - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - Document whose original state should 
//																		be changed.
//                 * SourceDocumentOriginalState - CatalogRef.SourceDocumentsOriginalsStates -
//                                                           The current state of a source document.
//                 * SourceDocument - String - A source document ID. 
//                                                Required if the state is not aggregated.
//                 * FromOutside			   - Boolean - "True" if the source document was added manually.
//                                                It's required if the current state is not aggregated. 
//  OriginalState 	- CatalogRef.SourceDocumentsOriginalsStates - Reference to the state to apply.
//
// Returns:  
//  Boolean - If True, the source document's state is not repeated and was saved.
//
Function SetTheNewStateOfTheOriginalArray(Val WritingObjects, Val OriginalState)

	IsChanged = False;
	
	Block = New DataLock();

	BeginTransaction();
	Try
		
		For Each Record In WritingObjects Do
			LockItem = Block.Add("InformationRegister.SourceDocumentsOriginalsStates");
			LockItem.SetValue("Owner", Record.Ref); 
		EndDo;
		Block.Lock();

		For Each Record In WritingObjects Do
	
			If Record.SourceDocumentOriginalState = OriginalState Then
				Continue;
			EndIf;
			
			If Record.OverallState Then
				RecordSet = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordSet();
				RecordSet.Filter.Owner.Set(Record.Ref);
				RecordSet.Filter.OverallState.Set(False);
				RecordSet.Read();
	
				If RecordSet.Count() = 0 Then
					IsChanged = True;
					WriteCommonDocumentOriginalState(Record.Ref, OriginalState);
					Continue;
				EndIf;
					
				For Each PreviousRecord1 In RecordSet Do
					If PreviousRecord1.State = OriginalState Then
						Continue;
					EndIf; 
					IsChanged = True;
					TabularSection = TableOfEmployees(Record.Ref);
					PreviousRecordEmployee = ?(TabularSection <> "", PreviousRecord1.Employee, Undefined);
					WriteDocumentOriginalStateByPrintForms(Record.Ref,
						PreviousRecord1.SourceDocument, PreviousRecord1.SourceDocumentPresentation, OriginalState,
						PreviousRecord1.ExternalForm, PreviousRecordEmployee);
				EndDo;
	
				IsChanged = True;
				WriteCommonDocumentOriginalState(Record.Ref, OriginalState);
				Continue;
			EndIf;
			
			RecordSet = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordSet();
			RecordSet.Filter.Owner.Set(Record.Ref);
			RecordSet.Read();
			If RecordSet.Count() = 0 Then
				IsChanged = True;
				WriteCommonDocumentOriginalState(Record.Ref, OriginalState);
				Continue;
			EndIf;
			
			RecordSet.Filter.SourceDocument.Set(Record.SourceDocument);
			RecordSet.Read();
			TabularSection = TableOfEmployees(Record.Ref); 
			If TabularSection <> "" Then
				IsStatesChanged = WriteOriginalStateByEmployees(RecordSet, Record.Ref, 
					TabularSection, OriginalState);
			Else
				IsStatesChanged = WriteOriginalStateByPrintForms(RecordSet, Record.Ref, 
					OriginalState);
			EndIf;
			IsChanged = IsChanged Or IsStatesChanged; 
			If IsChanged Then
				WriteCommonDocumentOriginalState(Record.Ref, OriginalState);
			EndIf;
	
		EndDo;
		
		CommitTransaction();
		
	Except	
		RollbackTransaction();
		Raise;
	EndTry;
		
	Return IsChanged;

EndFunction

// Parameters:
//   Document - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - Document whose original state should 
//																			 be changed.
//   OriginalState 	- CatalogRef.SourceDocumentsOriginalsStates - Reference to the state to apply.
//
// Returns:
//   Boolean - If True, the source document's state is not repeated and was saved.
//
Function SetNewStatusForOriginalDoc(Val Document, Val OriginalState)
	
	Block = New DataLock();
	LockItem = Block.Add("InformationRegister.SourceDocumentsOriginalsStates");
	LockItem.SetValue("Owner", Document); 

	BeginTransaction();
	Try
		
		Block.Lock();
		RecordSet = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordSet();
		RecordSet.Filter.Owner.Set(Document);
		RecordSet.Filter.OverallState.Set(True);  
		RecordSet.Read();
	
		If RecordSet.Count() And RecordSet[0].State = OriginalState Then
			CommitTransaction();
			Return False;
		EndIf;
				
		RecordSet.Filter.OverallState.Set(False);
		RecordSet.Read();
	
		If RecordSet.Count() > 0 Then
			TabularSection = TableOfEmployees(Document);
			If TabularSection <> "" Then
				WriteOriginalStateByEmployees(RecordSet, Document, TabularSection, OriginalState);
			Else
				WriteOriginalStateByPrintForms(RecordSet, Document, OriginalState);
			EndIf;
		EndIf;
		
		WriteCommonDocumentOriginalState(Document, 
			OriginalState);
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return True;

EndFunction

Function WriteOriginalStateByPrintForms(RecordSet, Document, OriginalState)
	
	IsChanged = False;
	For Each PreviousRecord1 In RecordSet Do
		If PreviousRecord1.State = OriginalState Then
			Continue;
		EndIf;
		IsChanged = True;
		WriteDocumentOriginalStateByPrintForms(Document, PreviousRecord1.SourceDocument, 
			PreviousRecord1.SourceDocumentPresentation, OriginalState, PreviousRecord1.ExternalForm);
	EndDo;
	Return IsChanged;
	
EndFunction

Function WriteOriginalStateByEmployees(RecordSet, Document, TabularSection, OriginalState)
	
	IsChanged = False;
	For Each Employee In Document[TabularSection] Do
		RecordSet.Filter.Employee.Set(Employee.Employee);
		RecordSet.Read();
		If RecordSet.Count() = 0 Then
			Continue;
		EndIf;

		For Each PreviousRecord1 In RecordSet Do
			If PreviousRecord1.State = OriginalState Then
				Continue;
			EndIf;
			IsChanged = True;
			WriteDocumentOriginalStateByPrintForms(Document, PreviousRecord1.SourceDocument, 
				PreviousRecord1.SourceDocumentPresentation, OriginalState, PreviousRecord1.ExternalForm, Employee.Employee);
		EndDo;
	EndDo;
	Return IsChanged;
	
EndFunction

// Fills in the drop-down choice list of states on the form.
//
//	Parameters:
//  Form - ClientApplicationForm - a form of the document list.
//
Procedure FillOriginalStatesChoiceList(Form, OriginalsStates)

	OriginalStatesChoiceList = Form.OriginalStatesChoiceList;
	OriginalStatesChoiceList.Clear();
	
	For Each State In OriginalsStates Do

		If State.Ref = Catalogs.SourceDocumentsOriginalsStates.OriginalReceived Then 
			OriginalStatesChoiceList.Add(State.Description, State.Description,,
				PictureLib.SourceDocumentOriginalStateOriginalReceived);
		ElsIf State.Ref = Catalogs.SourceDocumentsOriginalsStates.FormPrinted Then
			OriginalStatesChoiceList.Add(State.Description, State.Description,,
				PictureLib.SourceDocumentOriginalStateOriginalNotReceived);
		Else
			OriginalStatesChoiceList.Add(State.Description, State.Description);
		EndIf;

	EndDo;

EndProcedure

// Returns an array of states available to a user.
//
//	Returns:
//  ValueTable:
//    * Description - String - a description of the original state;
//    * Ref		 - CatalogRef.SourceDocumentsOriginalsStates
//
Function UsedStates()Export 

	SetPrivilegedMode(True);

	Query = New Query;
	Query.Text = "SELECT ALLOWED
	               |	SourceDocumentsOriginalsStates.Description AS Description,
	               |	SourceDocumentsOriginalsStates.Ref AS Ref
	               |FROM
	               |	Catalog.SourceDocumentsOriginalsStates AS SourceDocumentsOriginalsStates
	               |WHERE
	               |	NOT SourceDocumentsOriginalsStates.Ref = VALUE(Catalog.SourceDocumentsOriginalsStates.OriginalsNotAll)
	               |	AND NOT SourceDocumentsOriginalsStates.DeletionMark
	               |
	               |ORDER BY
	               |	SourceDocumentsOriginalsStates.AddlOrderingAttribute";

	Selection = Query.Execute();
	
	SetPrivilegedMode(False);

	Return Selection.Unload();

EndFunction

// Returns the record key of the source document's aggregated state by reference.
//
//	Parameters:
//  DocumentRef - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - Reference to the document for which the record key 
//																		of the aggregated state must be received. 
//
//	Returns:
//  InformationRegisterRecordKey.SourceDocumentsOriginalsStates
//
Function OverallStateRecordKey(DocumentRef) Export

	Query = New Query;
	Query.Text ="SELECT ALLOWED
	|	SourceDocumentsOriginalsStates.Owner AS Owner,
	|	SourceDocumentsOriginalsStates.SourceDocument AS SourceDocument,
	|	SourceDocumentsOriginalsStates.OverallState AS OverallState,
	|	SourceDocumentsOriginalsStates.ExternalForm AS ExternalForm,
	|	SourceDocumentsOriginalsStates.Employee AS Employee
	|FROM
	|	InformationRegister.SourceDocumentsOriginalsStates AS SourceDocumentsOriginalsStates
	|WHERE
	|	SourceDocumentsOriginalsStates.Owner = &Ref
	|	AND SourceDocumentsOriginalsStates.OverallState";
	
	Query.SetParameter("Ref",DocumentRef);

	Selection = Query.Execute().Unload();

	For Each Var_Key In Selection Do
		TransmittedParameters = New Structure("Owner, SourceDocument, OverallState, ExternalForm, Employee");
		FillPropertyValues(TransmittedParameters,Var_Key);

		ParametersArray1 = New Array;
		ParametersArray1.Add(TransmittedParameters);

		RegisterRecordKey = New("InformationRegisterRecordKey.SourceDocumentsOriginalsStates", ParametersArray1);
	EndDo;

	Return RegisterRecordKey;

EndFunction

// Checks and returns a flag indicating whether the document by reference is a document with originals recording.
//
// Parameters:
//  DocumentRef - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - Reference to the document to be checked.
//                                                                                
//
// Returns:
//   Boolean
//
Function IsAccountingObject(DocumentRef) Export

	If DocumentRef = Undefined Then
		Return False;
	EndIf;
	
	Return Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type.ContainsType(TypeOf(DocumentRef));

EndFunction

// Looks up for employees information in a document and returns the name of the table that contains it.
//
//	Parameters:
//  DocumentRef - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - Reference to the document to be checked.
//                                                                                
//
//	Returns:
//  String - The name of the table containing employees.
//           It is empty if the document does not contain multiple employees.
//
Function TableOfEmployees(DocumentRef) Export
	
	ListOfObjects = New Map();
	Result = "";
	SSLSubsystemsIntegration.WhenDeterminingMultiEmployeeDocuments(ListOfObjects);
	SourceDocumentsOriginalsRecordingOverridable.WhenDeterminingMultiEmployeeDocuments(ListOfObjects);
	DocumentType = Common.TableNameByRef(DocumentRef);
	If ListOfObjects[DocumentType] <> Undefined Then
		Result = ListOfObjects[DocumentType];
	EndIf;
	
	Return Result;
	
EndFunction

// Returns an array with type details of objects attached to the subsystem.
//
//	Returns:
//  Array of Type
//
Function InformationAboutConnectedObjects() Export

	AvailableTypes = Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type.Types();
	Return AvailableTypes;

EndFunction

// Returns a reference to the document by the spreadsheet document barcode.
//
// Parameters:
//  Barcode - String
//  Managers - Array of CatalogRef
//            - DocumentRef
//            - TaskRef
//
// Returns:
//  Array of DocumentRef
//
Function RefBySpreadsheetDocumentBarcode(Barcode, Managers = Undefined) 

	If Not StringFunctionsClientServer.OnlyNumbersInString(Barcode, False, False)
		Or TrimAll(Barcode) = "" Then
		Return New Array;
	EndIf;

	BarcodeInHexadecimal = ConvertDecimalToHexadecimalNotation(Number(Barcode));
	While StrLen(BarcodeInHexadecimal) < 32 Do
		BarcodeInHexadecimal = "0" + BarcodeInHexadecimal;
	EndDo;

	Id = Mid(BarcodeInHexadecimal, 1,  8)
		+ "-" + Mid(BarcodeInHexadecimal, 9,  4)
		+ "-" + Mid(BarcodeInHexadecimal, 13, 4)
		+ "-" + Mid(BarcodeInHexadecimal, 17, 4)
		+ "-" + Mid(BarcodeInHexadecimal, 21, 12);

	If StrLen(Id) <> 36 Then
		Return New Array;
	EndIf;

	If Managers = Undefined Then
		ObjectsManagers = New Array();
		For Each MetadataItem In Metadata.Documents Do
			ObjectsManagers.Add(Documents[MetadataItem.Name]);
		EndDo;
	Else
		ObjectsManagers = New Array();
		For Each EmptyRef In Managers Do
			RefType = TypeOf(EmptyRef);
			
			If Documents.AllRefsType().ContainsType(RefType) Then
				ObjectsManagers.Add(Documents[EmptyRef.Metadata().Name]);
				
			ElsIf Catalogs.AllRefsType().ContainsType(RefType) Then
				ObjectsManagers.Add(Catalogs[EmptyRef.Metadata().Name]);
				
			ElsIf Tasks.AllRefsType(RefType).ContainsType(RefType) Then	
				ObjectsManagers.Add(Tasks[EmptyRef.Metadata().Name]);
				
			ElsIf BusinessProcesses.AllRefsType(RefType).ContainsType(RefType) Then	
				ObjectsManagers.Add(BusinessProcesses[EmptyRef.Metadata().Name]);
				
			ElsIf ChartsOfCharacteristicTypes.AllRefsType(RefType).ContainsType(RefType) Then
				ObjectsManagers.Add(ChartsOfCharacteristicTypes[EmptyRef.Metadata().Name]);
				
			Else
				ExceptionText = NStr("vi = 'Kiểu mã vạch không xác định ""%Type%"".';
									|ru = 'Неизвестный тип штрихкода ""%Type%"".';
									|en = 'Unknown barcode type: %Type%.'; fa = 'Unknown barcode type: %Type%.';
									|it = 'Unknown barcode type: %Type%.';
									|pl = 'Unknown barcode type: %Type%.';
									|tr = 'Bilinmeyen barkod türü ""%Type%"".'");
				ExceptionText = StrReplace(ExceptionText, "%Type%", RefType);				
				Raise ExceptionText;
			EndIf;

		EndDo;
	EndIf;

	Query = New Query;

	ReferencesArrray = New Array;
	FirstQuery = True;
	For Each Manager In ObjectsManagers Do

		Try
			Ref = Manager.GetRef(New UUID(Id));
		Except
			Continue;
		EndTry;
		
		RefMetadata = Ref.Metadata();
		If Not AccessRight("Read", RefMetadata) Then
			Continue;
		EndIf;
		
		ReferencesArrray.Add(Ref);
		
		If FirstQuery Then
			Query.Text = Query.Text +
			"SELECT ALLOWED Table.Ref AS Ref
			|FROM &TheMetadataLinksToTheFullName AS Table
			|WHERE Ref IN (&ReferencesArrray)
			|";
		Else	
			Query.Text = Query.Text + 
			"UNION ALL
			|
			|SELECT Table.Ref AS Ref
			|FROM &TheMetadataLinksToTheFullName AS Table
			|WHERE Ref IN (&ReferencesArrray)
			|";
		EndIf;
		
		Query.Text = StrReplace(Query.Text, "&TheMetadataLinksToTheFullName", RefMetadata.FullName());
		FirstQuery = False;

	EndDo;

	If Not FirstQuery Then
		Query.Parameters.Insert("ReferencesArrray", ReferencesArrray);
		Return Query.Execute().Unload().UnloadColumn("Ref");
	Else
		Return New Array;
	EndIf;

EndFunction

// The procedure processes actions of originals recording after scanning the document barcode.
//
// Parameters:
//   Barcode - String - the scanned document barcode.
//
Procedure ProcessBarcode(Barcode) Export

	RefByBarcode = RefBySpreadsheetDocumentBarcode(Barcode);
	SetNewOriginalState(RefByBarcode[0], 
		Catalogs.SourceDocumentsOriginalsStates.OriginalReceived);

EndProcedure

// After recording states of document print forms to the register, checks whether the print forms have the same states.
//
// Parameters:
//  DocumentRef - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - Reference to the document 
//																			whose print form states must be checked.
//  OriginalState 	- CatalogRef.SourceDocumentsOriginalsStates - Reference to the state being checked.
//
// Returns:
//   Boolean - True if all the document print forms have the same state.
//
Function PrintFormsStateSame(DocumentRef, OriginalState) Export

	FormsStateSame = False;

	Query = New Query;
	Query.Text = "SELECT TOP 1
	               |	TRUE AS TrueValue
	               |FROM
	               |	InformationRegister.SourceDocumentsOriginalsStates AS SourceDocumentsOriginalsStates
	               |WHERE
	               |	SourceDocumentsOriginalsStates.Owner = &Ref
	               |	AND SourceDocumentsOriginalsStates.State <> &OriginalState
	               |	AND NOT SourceDocumentsOriginalsStates.OverallState";
	Query.SetParameter("Ref", DocumentRef);
	Query.SetParameter("OriginalState", OriginalState);
		
	If Query.Execute().IsEmpty() Then
		Return True;
	EndIf;

	Return FormsStateSame;

EndFunction

// Update handler procedure that populates initial items of the "States of source document originals" catalog.
Procedure WriteSourceDocumentOriginalState() Export

	OriginalState = Catalogs.SourceDocumentsOriginalsStates.FormPrinted.GetObject();
	LockDataForEdit(OriginalState.Ref);
	OriginalState.Description = NStr("vi = 'Biểu mẫu đã in';
									|ru = 'Форма напечатана';
									|en = 'Form printed'; fa = 'Form printed';
									|it = 'Modulo stampato';
									|pl = 'Wydrukowano formularz';
									|tr = 'Form yazdırıldı'", Common.DefaultLanguageCode());
	OriginalState.LongDesc = NStr("vi = 'Trạng thái cho thấy mẫu in mẫu in chỉ được in.';
									|ru = 'Состояние, означающее, что  печатная форма только печаталась.';
									|en = 'State that means that the print form was printed only.'; fa = 'State that means that the print form was printed only.';
									|it = 'Stato che indica che il modulo di stampa è stato solo stampato.';
									|pl = 'Status, oznaczający, że formularz wydruku była tylko drukowana.';
									|tr = 'Yazdırma formunun yeni yazdırıldığı anlamına gelen durum'", 
		Common.DefaultLanguageCode());
	OriginalState.AddlOrderingAttribute = 1;
	InfobaseUpdate.WriteObject(OriginalState);

	OriginalState = Catalogs.SourceDocumentsOriginalsStates.OriginalsNotAll.GetObject();
	LockDataForEdit(OriginalState.Ref);
	OriginalState.Description = NStr("vi = 'Tất cả không phải là bản gốc';
									|ru = 'Оригиналы не все';
									|en = 'Not all originals'; fa = 'Not all originals';
									|it = 'Originali non tutti';
									|pl = 'Nie wszystkie oryginały';
									|tr = 'Asılların hepsi değil'", Common.DefaultLanguageCode());
	OriginalState.LongDesc = NStr("vi = 'Trạng thái chung đối với chứng từ, trong đó các bản gốc của mẫu in có các trạng thái khác nhau.';
									|ru = 'Общее состояние для документа, у которого оригиналы печатных форм находятся в разных состояниях.';
									|en = 'The aggregated state of a document whose print forms have different states.'; fa = 'The aggregated state of a document whose print forms have different states.';
									|it = 'Stato generale per il documento di cui gli originali dei moduli di stampa sono negli stati diversi.';
									|pl = 'Ogólny status dla dokumentu, który nie ma oryginałów formularzy wydruku ma różne statusy.';
									|tr = 'Yazdırma formlarının asılları farklı durumlarda olan bir belgenin paylaşımlı durumu.'", 
		Common.DefaultLanguageCode());
	OriginalState.AddlOrderingAttribute = 99998;
	InfobaseUpdate.WriteObject(OriginalState);

	OriginalState = Catalogs.SourceDocumentsOriginalsStates.OriginalReceived.GetObject();
	LockDataForEdit(OriginalState.Ref);
	OriginalState.Description = NStr("vi = 'Đã nhận bản gốc';
									|ru = 'Оригинал получен';
									|en = 'Original received'; fa = 'Original received';
									|it = 'Originale ricevuto';
									|pl = 'Otrzymano oryginał';
									|tr = 'Aslı alındı'", Common.DefaultLanguageCode());
	OriginalState.LongDesc = NStr("vi = 'Trạng thái cho thấy có sẵn bản gốc mẫu in đã ký.';
									|ru = 'Состояние, означающее, что подписанный оригинал печатной формы есть в наличии.';
									|en = 'State that means that the signed print form original is available.'; fa = 'State that means that the signed print form original is available.';
									|it = 'Stato che indica che l''originale firmato del modulo di stampa è presente.';
									|pl = 'Status, oznaczający, że podpisany oryginał formularza wydruku jest w posiadaniu.';
									|tr = 'Yazdırma formunun imzalı aslının mevcut olduğunu gösteren durum.'", 
		Common.DefaultLanguageCode());
	OriginalState.AddlOrderingAttribute = 99999;
	InfobaseUpdate.WriteObject(OriginalState);

EndProcedure

Function ConvertDecimalToHexadecimalNotation(Val Decimal)

	Result = "";

	While Decimal > 0 Do
		Remainder = Decimal % 16;
		Decimal = (Decimal - Remainder) / 16;
		Result = Mid("0123456789abcdef", Remainder + 1, 1) + Result;
	EndDo;

	Return Result;
	
EndFunction

// Overrides value lists of print objects and their templates.
//
// Parameters:
//  PrintObjects - ValueList - Print object references.
//  PrintList - ValueList - Template names and print form presentations.
//
Procedure WhenDeterminingTheListOfPrintedForms(PrintObjects, PrintList) Export
	
	AccountingTableForOriginals = AccountingTableForOriginals();
	If AccountingTableForOriginals.Count() = 0 Then
		Return;
	EndIf;
	
	TemplatesNames = New Array;
	For Each Template In PrintList Do
		TemplatesNames.Add(Template.Value);
	EndDo;
	
	MetadataCompliance = New Map();
	For Each PrintObject In PrintObjects Do
		MetadataCompliance.Insert(PrintObject.Value.Metadata());
	EndDo;
	MetadataObjects = Common.UnloadColumn(MetadataCompliance, "Key");
	
	DeleteLayouts = New Array;
	For Each MetadataObject In MetadataObjects Do
		FoundRows = AccountingTableForOriginals.FindRows(New Structure("MetadataObject", MetadataObject));
		If FoundRows.Count() = 0 Then
			Continue;
		EndIf;
		LeaveLayouts = Common.UnloadColumn(FoundRows, "Id");
		For Each Template In TemplatesNames Do
			If LeaveLayouts.Find(Template) = Undefined Then
				DeleteLayouts.Add(Template);
			EndIf;
		EndDo;
	EndDo;
	
	For Each Template In DeleteLayouts Do
		FoundTemplate = PrintList.FindByValue(Template);
		If FoundTemplate <> Undefined Then
			PrintList.Delete(FoundTemplate);
		EndIf;
	EndDo;

EndProcedure

Function AccountingTableForOriginals()
	
	Table = New ValueTable;
	Table.Columns.Add("MetadataObject", New TypeDescription("MetadataObject"));
	Table.Columns.Add("Id", New TypeDescription("String"));
	
	SSLSubsystemsIntegration.OnFillTableOfOriginalsRecording(Table);
	SourceDocumentsOriginalsRecordingOverridable.FillInTheOriginalAccountingTable(Table);
	Return Table;
	
EndFunction

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("WriteSourceDocumentOriginalState");
	
EndProcedure

#EndRegion
