
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Title  = Title + " " + Parameters.Title;
	Count = Parameters.Count;
	Control   = Parameters.Control;
	Protocol.Load(Parameters.Protocol.Unload());
	
	Parameters.Property("ProductionOperation", ProductionOperation);
	Parameters.Property("Operation", Operation);
	
	CurrentUser = Users.CurrentUser();
	YouCanCancel       = True;
	For IndexOf = -(Protocol.Count() - 1) To 0 Do
		
		CurrentRow = Protocol[-IndexOf];
		
		YouCanCancel = Min(YouCanCancel, CurrentUser = CurrentRow.EmployeeResponsible);
		CurrentRow.YouCanCancel = YouCanCancel;
		
	EndDo;
	
	UnitOfMeasurePresentation = ProductionManagementClientServer.PresentationOfUnitOfOperation(
		Undefined,
		Count);
	
	Documents.ProductionOperation2_2.RecalcTotals(ThisObject);
	
	CustomizeFormElements();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		ShowQueryBox(
			New CallbackDescription("BeforeCloseCompletion", ThisObject),
			NStr("vi = 'Biên bản đã thay đổi. Lưu lại thay đổi?';
				|ru = 'Протокол был изменен. Сохранить изменения?';
				|en = 'The protocol was changed. Do you want to save the changes?'; fa = 'The protocol was changed. Do you want to save the changes?';
				|it = 'Il protocollo è stato modificato. Salvare le modifiche?';
				|pl = 'Protokół został zmieniony. Zapisać zmiany?';
				|tr = 'Protokol değiştirildi. Değişiklikler kaydedilsin mi?'"),
			QuestionDialogMode.YesNoCancel);
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProtocol

&AtClient
Procedure CancelProtocolOnChange(Item)
	
	CurrentData = Items.Protocol.CurrentData;
	
	Begin = ?(CurrentData.Mark, Protocol.IndexOf(CurrentData) + 1, 0);
	End  = ?(CurrentData.Mark, Protocol.Count() - 1, Protocol.IndexOf(CurrentData) - 1);
	
	For IndexOf = Begin To End Do
		Protocol[IndexOf].Mark = CurrentData.Mark;
	EndDo;
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CheckAll(Command)
	
	SetRemoveMarks(ThisObject, True);
	
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	
	SetRemoveMarks(ThisObject, False);
	
EndProcedure

&AtClient
Procedure DeleteSelectedItems(Command)
	
	DeleteSelectedOnesOnServer();
	
EndProcedure

&AtClient
Procedure Apply(Command)
	
	Modified = False;
	
	SaveAndLoad();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CancelProtocol.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Protocol.YouCanCancel");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	Settings = Documents.ProductionOperation2_2.RecalculateStandardsSwitchSettings(ProductionOperation);
	
	Items.RecalculateStandards.Visible      = Settings.Visible;
	Items.RecalculateStandards.Title      = Settings.Title;
	Items.RecalculateStandards.ReadOnly = ReadOnly;

	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("Marks")
		Or Initialize Then
		
		ThereAreAvailableCheckboxes     = ThereAreAvailableCheckboxes(Form);
		ThereAreCheckboxesSet = ThereAreCheckboxesSet(Form);
		
		Items.FormCheckAll.Enabled = Not Form.ReadOnly And ThereAreAvailableCheckboxes;
		Items.FormUncheckAll.Enabled      = Not Form.ReadOnly And ThereAreAvailableCheckboxes;
		Items.FormDeleteSelectedItems.Enabled = Not Form.ReadOnly And ThereAreCheckboxesSet;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetRemoveMarks(Form, Value)
	
	For Each String In Form.Protocol Do
		If Not String.YouCanCancel Then
			Continue;
		EndIf;
		String.Mark = Value;
	EndDo;
	
	ConfigureDependentFormElements(Form, "Marks");
	
EndProcedure

&AtClientAtServerNoContext
Function ThereAreAvailableCheckboxes(Form)
	
	Return Form.Protocol.FindRows(New Structure("YouCanCancel", True)).Count() > 0;
	
EndFunction

&AtClientAtServerNoContext
Function ThereAreCheckboxesSet(Form)
	
	Return Form.Protocol.FindRows(New Structure("Mark", True)).Count() > 0;
	
EndFunction

&AtServer
Procedure DeleteSelectedOnesOnServer()
	
	RecordsCount = Protocol.Count();
	
	For IndexOf = -RecordsCount + 1 To 0 Do
		RecordingProtocol = Protocol[-IndexOf];
		If RecordingProtocol.Mark Then
			If Items.RecalculateStandards.Visible
				And (RecordingProtocol.Event = Enums.RoutingOperationProtocolEvents.Cancel
					Or RecordingProtocol.Event = Enums.RoutingOperationProtocolEvents.DefectiveGoods) Then
				RecalculateStandards = True;
			EndIf;
			Protocol.Delete(-IndexOf);
		EndIf;
	EndDo;
	
	If RecordsCount <> Protocol.Count() Then
		Documents.ProductionOperation2_2.RecalcTotals(ThisObject);
		Modified = True;
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "Marks");
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	Modified = False;
	
	If QuestionResult = DialogReturnCode.Yes Then
		SaveAndLoad();
	Else
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveAndLoad()
	
	Result = New Structure;
	Result.Insert("Protocol", Protocol);
	Result.Insert("RecalculateStandards", RecalculateStandards);
	
	Close(Result);
	
EndProcedure

#EndRegion