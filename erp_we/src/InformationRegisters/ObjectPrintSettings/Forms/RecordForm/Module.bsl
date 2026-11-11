
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);

	TableOfObjectsForCompletePrinting = InformationRegisters.ObjectPrintSettings.TableOfObjectsForCompletePrinting();
	For Each CurRow In TableOfObjectsForCompletePrinting Do
		Items.ObjectType.ChoiceList.Add(CurRow.ObjectType, CurRow.Presentation);
	EndDo;
	
	WhenChangingTypeOfServerObject();
	
	If Not UserRightsCached.AddEditObjectPrintSettings() Then
		
		ReadOnly = True;
		
		If Record.SourceRecordKey.IsEmpty() Then
			Record.Partner = Undefined;
		ElsIf ValueIsFilled(Record.Partner) Then
			TMCommonUseClientServer.SetFormItemProperty(Items, "FormDelete", "Visible", False);
		EndIf;
		
	EndIf;
	
	If Not UserRightsCached.SaveObjectPrintSettingsByDefault() Then
		
		Items.Organization.ReadOnly = True;
		
		If Record.SourceRecordKey.IsEmpty() Then
			Record.Organization = Undefined;
		ElsIf ValueIsFilled(Record.Organization) Then
			TMCommonUseClientServer.SetFormItemProperty(Items, "FormDelete", "Visible", False);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	InformationRegisters.ObjectPrintSettings.KitOfPrintingPlatesIsSet(PrintFormsSet, Cancel);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not UserRightsCached.AddEditObjectPrintSettings()
	 And ValueIsFilled(CurrentObject.Partner) Then
		
		Cancel = True;
		CommonClientServer.MessageToUser(NStr("vi = 'Không có quyền ghi lại tùy chỉnh in theo bạn hàng';
												|ru = 'Нет прав на запись настройки печати по партнеру';
												|en = 'No rights to save partner print settings'; fa = 'No rights to save partner print settings';
												|it = 'Diritti insufficienti per registrare le impostazioni di stampa relative al partner';
												|pl = 'Brak uprawnień do zapisywania ustawień drukowania wg partnera';
												|tr = 'İş ortağı için yazdırma ayarının kaydedilmesine erişim yetkisi yok'"));
		
	EndIf;
	
	If Not UserRightsCached.SaveObjectPrintSettingsByDefault()
	 And ValueIsFilled(CurrentObject.Organization) Then
		
		Cancel = True;
		CommonClientServer.MessageToUser(NStr("vi = 'Không có quyền ghi lại tùy chỉnh mẫu in theo doanh nghiệp';
												|ru = 'Нет прав на запись настройки печати по организации';
												|en = 'No rights to save company print settings'; fa = 'No rights to save company print settings';
												|it = 'Diritti insufficienti per registrare le impostazioni di stampa relative all''azienda';
												|pl = 'Brak uprawnień do zapisywania ustawień drukowania wg firmy';
												|tr = 'İş yeri için yazdırma ayarının kaydedilmesine erişim yetkisi yok'"));
		
	EndIf;
	
	If PrintFormsSet.FindRows(New Structure("Print", True)).Count() = 0 Then
		
		Cancel = True;
		MessageText = NStr("vi = 'Hãy chọn ít nhất một mẫu in.';
							|ru = 'Выберите хотя бы одну печатную форму.';
							|en = 'Select at least one print form.'; fa = 'Select at least one print form.';
							|it = 'Seleziona almeno un modulo di stampa.';
							|pl = 'Wybierz co najmniej jeden formularz do drukowania.';
							|tr = 'En az bir yazdırma formu seç'");
		CommonClientServer.MessageToUser(MessageText, , "PrintFormsSet");
		
	EndIf;

	CurrentObject.Settings = New ValueStorage(PrintFormsSet.Unload());
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ObjectPrintSettings");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ObjectTypeOnChange(Item)
	
	WhenChangingTypeOfServerObject();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CheckAll(Command)
	
	For Each CurRow In PrintFormsSet Do
		CurRow.Print = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure UncheckAll(Command)
	
	For Each CurRow In PrintFormsSet Do
		CurRow.Print = False;
	EndDo;
	
EndProcedure

&AtClient
Procedure CustomizeStandardSettings(Command)
	
	CustomizeStandardSettingsServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PrintFormsSetCopies2.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PrintFormsSet.Print");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PrintFormsSetPresentation.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PrintFormsSetCopies2.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PrintFormsSet.Print");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

EndProcedure

&AtServer
Procedure CustomizeStandardSettingsServer()
	
	If Not ValueIsFilled(Record.ObjectType) Then
		Return;
	EndIf;
	
	PrintFormsSet.Clear();
	ObjectManager = Common.ObjectManagerByFullName(Record.ObjectType);
	PrintFormsCollection = ObjectManager.PrintFormsSet();
	InformationRegisters.ObjectPrintSettings.AddExternalPrintFormsToSet(Record.ObjectType, PrintFormsCollection);
	
	For Each CurRow In PrintFormsCollection Do
		
		NewRow = PrintFormsSet.Add();
		FillPropertyValues(NewRow, CurRow);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure WhenChangingTypeOfServerObject()
	
	ObjectParameters = InformationRegisters.ObjectPrintSettings.ObjectParametersForCompletePrinting(Record.ObjectType);
	
	Items.Organization.Enabled = ObjectParameters.ThereIsACompany;
	Items.Partner.Enabled = ObjectParameters.ThereIsAPartner;
	Items.PrintFormsSet.Enabled = ObjectParameters.KitPrintingIsAvailable;
	
	If Not ObjectParameters.ThereIsACompany Then
		Record.Organization = Undefined;
	EndIf;
	
	If Not ObjectParameters.ThereIsAPartner Then
		Record.Partner = Undefined;
	EndIf;
	
	If ObjectParameters.KitPrintingIsAvailable Then
		
		RecordObject = FormAttributeToValue("Record");
		RecordObject.Read();
		SavedValue = RecordObject.Settings.Get();
		
		// Default setting
		If SavedValue = Undefined Then
			CustomizeStandardSettingsServer();
		Else
			PrintFormsSet.Load(SavedValue);
		EndIf;
		
	Else
		
		PrintFormsSet.Clear();
		
	EndIf;
	
EndProcedure

#EndRegion
