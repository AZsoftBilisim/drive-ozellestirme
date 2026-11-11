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
	
	If Not Parameters.Property("OpenByScenario") Then
		Raise NStr("vi = 'Bộ xử lý không được dùng để sử dụng trực tiếp.';
					|ru = 'Обработка не предназначена для непосредственного использования.';
					|en = 'The data processor cannot be opened manually.'; fa = 'The data processor cannot be opened manually.';
					|it = 'L''elaborazione non è destinata all''uso diretto.';
					|pl = 'Przetwarzanie nie jest przeznaczone do bezpośredniego używania.';
					|tr = 'Bu veri işlemcisi manuel kullanıma yönelik değildir.'");
	EndIf;
	
	ThisDataProcessor = ThisObject();
	If IsBlankString(Parameters.ObjectAddress) Then
		ThisObject( ThisDataProcessor.InitializeThisObject(Parameters.ObjectSettings) );
	Else
		ThisObject( ThisDataProcessor.InitializeThisObject(Parameters.ObjectAddress) );
	EndIf;
	
	If Not ValueIsFilled(Object.InfobaseNode) Then
		Text = NStr("vi = 'Không tìm thấy tùy chỉnh trao đổi dữ liệu.';
					|ru = 'Настройка обмена данными не найдена.';
					|en = 'The data exchange setting is not found.'; fa = 'The data exchange setting is not found.';
					|it = 'Configurazione di scambio dati non è stata trovata.';
					|pl = 'Nie znaleziono ustawienia wymiany danych.';
					|tr = 'Veri değişimi ayarı bulunmadı.'");
		DataExchangeServer.ReportError(Text, Cancel);
		Return;
	EndIf;
	
	Title = Title + " (" + Object.InfobaseNode + ")";
	BaseNameForForm = ThisDataProcessor.BaseNameForForm();
	
	CurrentSettingsItemPresentation = "";
	Items.FiltersSettings.Visible = AccessRight("SaveUserData", Metadata);
	
	ResetTableCountLabel();
	UpdateTotalCountLabel();
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	StopCountCalculation();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AdditionalRegistrationSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field <> Items.AdditionalRegistrationFilterAsString Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	CurrentData = Items.AdditionalRegistration.CurrentData;
	
	NameOfFormToOpen_ = BaseNameForForm + "Form.PeriodAndFilterEdit";
	FormParameters = New Structure;
	FormParameters.Insert("Title",           CurrentData.Presentation);
	FormParameters.Insert("ChoiceAction",      - Items.AdditionalRegistration.CurrentRow);
	FormParameters.Insert("PeriodSelection",        CurrentData.PeriodSelection);
	FormParameters.Insert("SettingsComposer", SettingsComposerByTableName(CurrentData.FullMetadataName, CurrentData.Presentation, CurrentData.Filter));
	FormParameters.Insert("DataPeriod",        CurrentData.Period);
	
	FormParameters.Insert("FormStorageAddress", UUID);
	
	OpenForm(NameOfFormToOpen_, FormParameters, Items.AdditionalRegistration);
EndProcedure

&AtClient
Procedure AdditionalRegistrationBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	Cancel = True;
	If Copy Then
		Return;
	EndIf;
	
	OpenForm(BaseNameForForm + "Form.SelectNodeCompositionObjectKind",
		New Structure("InfobaseNode", Object.InfobaseNode),
		Items.AdditionalRegistration);
EndProcedure

&AtClient
Procedure AdditionalRegistrationBeforeDeleteRow(Item, Cancel)
	Selected3 = Items.AdditionalRegistration.SelectedRows;
	Count = Selected3.Count();
	If Count>1 Then
		PresentationText = NStr("vi = 'dòng đã chọn';
								|ru = 'выбранные строки';
								|en = 'the selected lines'; fa = 'the selected lines';
								|it = 'righe selezionate';
								|pl = 'wybrane wiersze';
								|tr = 'seçilen satırlar'");
	ElsIf Count=1 Then
		PresentationText = Items.AdditionalRegistration.CurrentData.Presentation;
	Else
		Return;
	EndIf;
	
	// The AdditionalRegistrationBeforeDeleteEnd procedure is called from the user confirmation dialog.
	Cancel = True;
	
	QueryText = NStr("vi = 'Xóa khỏi dữ liệu bổ sung %1?';
					|ru = 'Удалить из дополнительных данных %1 ?';
					|en = 'Do you want to delete %1 from the additional data?'; fa = 'Do you want to delete %1 from the additional data?';
					|it = 'Rimuovere dai dati aggiuntivi %1 ?';
					|pl = 'Usunąć z dodatkowych danych %1 ?';
					|tr = 'Ek verilerden %1 silinsin mi?'");    
	QueryText = StrReplace(QueryText, "%1", PresentationText);
	
	QuestionTitle = NStr("vi = 'Xác nhận';
						|ru = 'Подтверждение';
						|en = 'Confirm operation'; fa = 'Confirm operation';
						|it = 'Conferma';
						|pl = 'Potwierdzenie';
						|tr = 'Parolayı doğrula'");
	
	Notification = New CallbackDescription("AdditionalRegistrationBeforeDeleteRowCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("SelectedRows", Selected3);
	
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo, , ,QuestionTitle);
EndProcedure

&AtClient
Procedure AdditionalRegistrationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	StandardProcessing = False;
	
	SelectedValueType = TypeOf(ValueSelected);
	If SelectedValueType=Type("Array") Then
		// Add a new row.
		Items.AdditionalRegistration.CurrentRow = AddingRowToAdditionalCompositionServer(ValueSelected);
		
	ElsIf SelectedValueType= Type("Structure") Then
		If ValueSelected.ChoiceAction=3 Then
			// Restore settings.
			SettingPresentation = ValueSelected.SettingPresentation;
			If Not IsBlankString(CurrentSettingsItemPresentation) And SettingPresentation<>CurrentSettingsItemPresentation Then
				QueryText  = NStr("vi = 'Khôi phục tùy chỉnh ""%1""?';
									|ru = 'Восстановить настройки ""%1""?';
									|en = 'Do you want to restore ""%1"" settings?'; fa = 'Do you want to restore ""%1"" settings?';
									|it = 'Ripristinare le configurazioni ""%1""?';
									|pl = 'Przywróć ustawienia ""%1""?';
									|tr = '""%1"" ayarları geri yüklensin mi?'");
				QueryText  = StrReplace(QueryText, "%1", SettingPresentation);
				TitleText = NStr("vi = 'Xác nhận';
								|ru = 'Подтверждение';
								|en = 'Confirm operation'; fa = 'Confirm operation';
								|it = 'Conferma';
								|pl = 'Potwierdzenie';
								|tr = 'Parolayı doğrula'");
				
				Notification = New CallbackDescription("AdditionalRegistrationChoiceProcessingCompletion", ThisObject, New Structure);
				Notification.AdditionalParameters.Insert("SettingPresentation", SettingPresentation);
				
				ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo, , , TitleText);
			Else
				CurrentSettingsItemPresentation = SettingPresentation;
			EndIf;
		Else
			// Editing filter condition, negative line number.
			Items.AdditionalRegistration.CurrentRow = FilterStringEditingAdditionalCompositionServer(ValueSelected);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AdditionalRegistrationAfterDeleteRow(Item)
	UpdateTotalCountLabel();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ConfirmSelection(Command)
	NotifyChoice( SelectionResultServer() );
EndProcedure

&AtClient
Procedure ShowCommonParametersText(Command)
	OpenForm(BaseNameForForm +  "Form.CommonSynchronizationSettings",
		New Structure("InfobaseNode", Object.InfobaseNode));
EndProcedure

&AtClient
Procedure ExportComposition(Command)
	OpenForm(BaseNameForForm + "Form.ExportComposition",
		New Structure("ObjectAddress", AdditionalExportObjectAddress() ));
EndProcedure

&AtClient
Procedure UpdateCountClient(Command)
	
	Result = UpdateCountServer();
	
	If Result.Status = "Running" Then
		
		Items.CountCalculationPicture.Visible = True;
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow  = False;
		IdleParameters.OutputMessages     = True;
		
		CallbackOnCompletion = New CallbackDescription("BackgroundJobCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(Result, CallbackOnCompletion, IdleParameters);
		
	Else
		AttachIdleHandler("ImportCountsValuesClient", 1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure FiltersSettings(Command)
	
	// Selecting from the list menu
	VariantList = ReadSettingsVariantListServer();
	
	Text = NStr("vi = 'Lưu lại tùy chỉnh hiện tại...';
				|ru = 'Сохранить текущую настройку...';
				|en = 'Save current setting…'; fa = 'Save current setting…';
				|it = 'Salvare la configurazione corrente...';
				|pl = 'Zapisz bieżące ustawienie ...';
				|tr = 'Mevcut ayarlar kaydediliyor...'");
	VariantList.Add(1, Text, , PictureLib.SaveReportSettings);
	
	Notification = New CallbackDescription("FiltersSettingsOptionSelectionCompletion", ThisObject);
	
	ShowChooseFromMenu(Notification, VariantList, Items.FiltersSettings);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ImportCountsValuesClient()
	Items.CountCalculationPicture.Visible = False;
	ImportCountsValuesServer();
EndProcedure

&AtClient
Procedure BackgroundJobCompletion(Result, AdditionalParameters) Export
	ImportCountsValuesClient();
EndProcedure

&AtClient
Procedure FiltersSettingsOptionSelectionCompletion(Val SelectedElement, Val AdditionalParameters) Export
	If SelectedElement = Undefined Then
		Return;
	EndIf;
		
	SettingPresentation = SelectedElement.Value;
	If TypeOf(SettingPresentation)=Type("String") Then
		TitleText = NStr("vi = 'Xác nhận';
						|ru = 'Подтверждение';
						|en = 'Confirm operation'; fa = 'Confirm operation';
						|it = 'Conferma';
						|pl = 'Potwierdzenie';
						|tr = 'Parolayı doğrula'");
		QueryText   = NStr("vi = 'Khôi phục tùy chỉnh ""%1""?';
							|ru = 'Восстановить настройки ""%1""?';
							|en = 'Do you want to restore ""%1"" settings?'; fa = 'Do you want to restore ""%1"" settings?';
							|it = 'Ripristinare le configurazioni ""%1""?';
							|pl = 'Przywróć ustawienia ""%1""?';
							|tr = '""%1"" ayarları geri yüklensin mi?'");
		QueryText   = StrReplace(QueryText, "%1", SettingPresentation);
		
		Notification = New CallbackDescription("FiltersSettingsCompletion", ThisObject, New Structure);
		Notification.AdditionalParameters.Insert("SettingPresentation", SettingPresentation);
		
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo, , , TitleText);
		
	ElsIf SettingPresentation=1 Then
		
		// Form that displays all settings.
		
		SettingsFormParameters = New Structure;
		SettingsFormParameters.Insert("CloseOnChoice", True);
		SettingsFormParameters.Insert("ChoiceAction", 3);
		SettingsFormParameters.Insert("Object", Object);
		SettingsFormParameters.Insert("CurrentSettingsItemPresentation", CurrentSettingsItemPresentation);
		
		SettingsFormName = BaseNameForForm + "Form.SettingsCompositionEdit";
		
		OpenForm(SettingsFormName, SettingsFormParameters, Items.AdditionalRegistration);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FiltersSettingsCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	SetSettingsServer(AdditionalParameters.SettingPresentation);
EndProcedure

&AtClient
Procedure AdditionalRegistrationChoiceProcessingCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	SetSettingsServer(AdditionalParameters.SettingPresentation);
EndProcedure

&AtClient
Procedure AdditionalRegistrationBeforeDeleteRowCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	DeletionTable = Object.AdditionalRegistration;
	SubjectToDeletion = New Array;
	For Each RowID In AdditionalParameters.SelectedRows Do
		RowToDelete = DeletionTable.FindByID(RowID);
		If RowToDelete<>Undefined Then
			SubjectToDeletion.Add(RowToDelete);
		EndIf;
	EndDo;
	For Each RowToDelete In SubjectToDeletion Do
		DeletionTable.Delete(RowToDelete);
	EndDo;
	
	UpdateTotalCountLabel();
EndProcedure

&AtServer
Function SelectionResultServer()
	ObjectResult = New Structure("InfobaseNode, ExportOption, AllDocumentsFilterComposer, AllDocumentsFilterPeriod");
	FillPropertyValues(ObjectResult, Object);
	
	ObjectResult.Insert("AdditionalRegistration", 
		TableIntoStructuresArray( FormAttributeToValue("Object.AdditionalRegistration")) );
	
	Return New Structure("ChoiceAction, ObjectAddress", 
		Parameters.ChoiceAction, PutToTempStorage(ObjectResult, UUID));
EndFunction

&AtServer
Function TableIntoStructuresArray(Val ValueTable)
	Result = New Array;
	
	ColumnsNames = "";
	For Each Column In ValueTable.Columns Do
		ColumnsNames = ColumnsNames + "," + Column.Name;
	EndDo;
	ColumnsNames = Mid(ColumnsNames, 2);
	
	For Each String In ValueTable Do
		StringStructure = New Structure(ColumnsNames);
		FillPropertyValues(StringStructure, String);
		Result.Add(StringStructure);
	EndDo;
	
	Return Result;
EndFunction

&AtServer
Function ThisObject(NewObject = Undefined)
	If NewObject=Undefined Then
		Return FormAttributeToValue("Object");
	EndIf;
	ValueToFormAttribute(NewObject, "Object");
	Return Undefined;
EndFunction

&AtServer
Function AddingRowToAdditionalCompositionServer(ChoiceArray)
	
	If ChoiceArray.Count()=1 Then
		String = AddToAdditionalExportComposition(ChoiceArray[0]);
	Else
		String = Undefined;
		For Each ChoiceItem In ChoiceArray Do
			TestRow = AddToAdditionalExportComposition(ChoiceItem);
			If String=Undefined Then
				String = TestRow;
			EndIf;
		EndDo;
	EndIf;
	
	Return String;
EndFunction

&AtServer 
Function FilterStringEditingAdditionalCompositionServer(ChoiceStructure)
	
	CurrentData = Object.AdditionalRegistration.FindByID(-ChoiceStructure.ChoiceAction);
	If CurrentData=Undefined Then
		Return Undefined
	EndIf;
	
	CurrentData.Period       = ChoiceStructure.DataPeriod;
	CurrentData.Filter        = ChoiceStructure.SettingsComposer.Settings.Filter;
	CurrentData.FilterAsString = FilterPresentation(CurrentData.Period, CurrentData.Filter);
	CurrentData.Count   = NStr("vi = 'Chưa tính';
								|ru = 'Не рассчитано';
								|en = 'Not calculated'; fa = 'محاسبه نشده';
								|it = 'Non calcolato';
								|pl = 'Nie obliczono ';
								|tr = 'Hesaplanmadı'");
	
	UpdateTotalCountLabel();
	
	Return ChoiceStructure.ChoiceAction;
EndFunction

&AtServer
Function AddToAdditionalExportComposition(Item)
	
	ExistingRows = Object.AdditionalRegistration.FindRows( 
		New Structure("FullMetadataName", Item.FullMetadataName));
	If ExistingRows.Count()>0 Then
		String = ExistingRows[0];
	Else
		String = Object.AdditionalRegistration.Add();
		FillPropertyValues(String, Item,,"Presentation");
		
		String.Presentation = Item.ListPresentation;
		String.FilterAsString  = FilterPresentation(String.Period, String.Filter);
		Object.AdditionalRegistration.Sort("Presentation");
		
		String.Count = NStr("vi = 'Chưa tính';
							|ru = 'Не рассчитано';
							|en = 'Not calculated'; fa = 'محاسبه نشده';
							|it = 'Non calcolato';
							|pl = 'Nie obliczono ';
							|tr = 'Hesaplanmadı'");
		UpdateTotalCountLabel();
	EndIf;
	
	Return String.GetID();
EndFunction

&AtServer
Function FilterPresentation(Period, Filter)
	Return ThisObject().FilterPresentation(Period, Filter);
EndFunction

&AtServer
Function SettingsComposerByTableName(TableName, Presentation, Filter)
	Return ThisObject().SettingsComposerByTableName(TableName, Presentation, Filter, UUID);
EndFunction

&AtServer
Procedure StopCountCalculation()
	
	TimeConsumingOperations.CancelJobExecution(BackgroundJobIdentifier);
	If Not IsBlankString(BackgroundJobResultAddress) Then
		DeleteFromTempStorage(BackgroundJobResultAddress);
	EndIf;
	
	BackgroundJobResultAddress = "";
	BackgroundJobIdentifier   = Undefined;
	
EndProcedure

&AtServer
Function UpdateCountServer()
	
	StopCountCalculation();
	
	JobParameters = New Structure;
	JobParameters.Insert("DataProcessorStructure", ThisObject().ThisObjectInStructureForBackgroundJob());
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = 
		NStr("vi = 'Tính số lượng đối tượng để gửi khi đồng bộ';
			|ru = 'Расчет количества объектов для отправки при синхронизации';
			|en = 'Calculate the number of objects to send during synchronization'; fa = 'Calculate the number of objects to send during synchronization';
			|it = 'Calcolo del numero di oggetti da inviare durante la sincronizzazione';
			|pl = 'Oblicz ilość obiektów do wysłania podczas synchronizacji';
			|tr = 'Senkronizasyon sırasında gönderilecek nesnelerin sayısının hesaplanması'");

	BackgroundJobStartResult = TimeConsumingOperations.ExecuteInBackground(
		"DataExchangeServer.InteractiveExportModificationGenerateValueTree",
		JobParameters,
		ExecutionParameters);
		
	BackgroundJobIdentifier   = BackgroundJobStartResult.JobID;
	BackgroundJobResultAddress = BackgroundJobStartResult.ResultAddress;
	
	Return BackgroundJobStartResult;
	
EndFunction

&AtServer
Procedure ImportCountsValuesServer()
	
	CountsTree = Undefined;
	If Not IsBlankString(BackgroundJobResultAddress) Then
		CountsTree = GetFromTempStorage(BackgroundJobResultAddress);
		DeleteFromTempStorage(BackgroundJobResultAddress);
	EndIf;
	If TypeOf(CountsTree) <> Type("ValueTree") Then
		CountsTree = New ValueTree;
	EndIf;
	
	If CountsTree.Rows.Count() = 0 Then
		UpdateTotalCountLabel(Undefined);
		Return;
	EndIf;
	
	ThisDataProcessor = ThisObject();
	
	CountRows = CountsTree.Rows;
	For Each String In Object.AdditionalRegistration Do
		
		TotalCount1 = 0;
		CountExport = 0;
		StringComposition = ThisDataProcessor.EnlargedMetadataGroupComposition(String.FullMetadataName);
		For Each TableName In StringComposition Do
			DataString1 = CountRows.Find(TableName, "FullMetadataName", False);
			If DataString1 <> Undefined Then
				CountExport = CountExport + DataString1.ToExportCount;
				TotalCount1     = TotalCount1     + DataString1.CommonCount;
			EndIf;
		EndDo;
		
		String.Count = Format(CountExport, "NZ=0") + " / " + Format(TotalCount1, "NZ=0");
	EndDo;
	
	// Grand totals.
	DataString1 = CountRows.Find(Undefined, "FullMetadataName", False);
	UpdateTotalCountLabel(?(DataString1 = Undefined, Undefined, DataString1.ToExportCount));
	
EndProcedure

&AtServer
Procedure UpdateTotalCountLabel(Count = Undefined) 
	
	StopCountCalculation();
	
	If Count = Undefined Then
		CountText = NStr("vi = '<không tính>';
						|ru = '<не рассчитано>';
						|en = '<not calculated>'; fa = '<not calculated>';
						|it = '<non calcolato>';
						|pl = '<nie obliczono>';
						|tr = '<hesaplanmadı>'");
	Else
		CountText = NStr("vi = 'Đối tượng: %1';
						|ru = 'Объектов: %1';
						|en = 'Objects: %1'; fa = 'Objects: %1';
						|it = 'Oggetti: %1';
						|pl = 'Obiektów: %1';
						|tr = 'Nesneler: %1'");
		CountText = StrReplace(CountText, "%1", Format(Count, "NZ=0"));
	EndIf;
	
	Items.UpdateCount.Title  = CountText;
EndProcedure

&AtServer
Procedure ResetTableCountLabel()
	CountsText = NStr("vi = 'Chưa tính';
						|ru = 'Не рассчитано';
						|en = 'Not calculated'; fa = 'محاسبه نشده';
						|it = 'Non calcolato';
						|pl = 'Nie obliczono ';
						|tr = 'Hesaplanmadı'");
	For Each String In Object.AdditionalRegistration Do
		String.Count = CountsText;
	EndDo;
	Items.CountCalculationPicture.Visible = False;
EndProcedure

&AtServer
Function ReadSettingsVariantListServer()
	VariantFilter = New Array;
	VariantFilter.Add(Object.ExportOption);
	
	Return ThisObject().ReadSettingsListPresentations(Object.InfobaseNode, VariantFilter);
EndFunction

&AtServer
Procedure SetSettingsServer(SettingPresentation)
	
	UnchangedData = New Structure("InfobaseNode, ExportOption, AllDocumentsFilterComposer, AllDocumentsFilterPeriod");
	FillPropertyValues(UnchangedData, Object);
	
	ThisDataProcessor = ThisObject();
	ThisDataProcessor.RestoreCurrentAttributesFromSettings(SettingPresentation);
	ThisObject(ThisDataProcessor);
	
	FillPropertyValues(Object, UnchangedData);
	
	ResetTableCountLabel();
	UpdateTotalCountLabel();
EndProcedure

&AtServer
Function AdditionalExportObjectAddress()
	Return ThisObject().SaveThisObject(UUID);
EndFunction

#EndRegion
