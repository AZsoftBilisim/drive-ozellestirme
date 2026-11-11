///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Sets the original state for selected documents. Called over the "Attachable commands" subsystem.
//
//	Parameters:
//  ReferencesArrray - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - Document reference.
//  Parameters -See AttachableCommands.CommandExecuteParameters.
//
Procedure Attachable_SetOriginalState(ReferencesArrray, Parameters) Export
	
	If TypeOf(Parameters.Source) = Type("FormTable") Then 
		SetOriginalStateListForm(Parameters, Parameters.Source);
	Else
		Ref = ReferencesArrray[0];
		SetOriginalStateDocumentForm(Ref, Parameters);
	EndIf;
	
EndProcedure

// Sets the original state for selected documents. Called without integrating the "Attachable commands" subsystem.
//
//	Parameters:
//  CommandName - String- Name of the form command being executed.
//  Form - ClientApplicationForm - a form of a list or a document.
//  List - FormTable - Form list where the state will be changed.
//  						"Undefined" if the state is being set from the document form.
//
Procedure SetOriginalState(CommandName, Form, List = Undefined) Export
	
	Parameters = AttachableCommandsClient.CommandExecuteParameters();
	
	Parameters.CommandDetails = New Structure("Id", CommandName);
	
	If CommandName = "SettingStateOriginalReceived" Then
		OriginalState = PredefinedValue("Catalog.SourceDocumentsOriginalsStates.OriginalReceived");
		AdditionalParameters = New Structure("RefToState", OriginalState);
		Parameters.CommandDetails.Insert("AdditionalParameters", AdditionalParameters);
	ElsIf Not CommandName = "StatesSetup" And Not CommandName = "ClarifyByPrintForms" Then
		OriginalState = SourceDocumentsOriginalsRecordingServerCall.SourceDocumentOriginalStateByCommandName(CommandName);
		AdditionalParameters = New Structure("RefToState", OriginalState);
		Parameters.CommandDetails.Insert("AdditionalParameters", AdditionalParameters);
	EndIf;

	If List = Undefined Then
		SetOriginalStateDocumentForm(Form.Object.Ref, Parameters);
		Return;
	EndIf;
	
	SetOriginalStateListForm(Parameters, List);
	
EndProcedure

// Opens a drop-down menu to select an original state in a list form or a document form.
//
//	Parameters:
//  Form - ClientApplicationForm - Form's main attribute.
//  Source - FormTable - A form's list or decoration where a drop-down list should be opened.
//                            If not specified, the "OriginalStateDecoration" element opens.
//
Procedure OpenStateSelectionMenu(Val Form, Val Source = Undefined) Export 
	
	If TypeOf(Source) = Undefined Then
		Source = Form.Items.Find("OriginalStateDecoration");
	EndIf;
	
	If TypeOf(Source) = Type("FormTable") Then
		RecordData = Source.CurrentData;
		Document = RecordData.Ref;
		ShouldClarifyByPrintForms = RecordData.OverallState 
			Or Not ValueIsFilled(RecordData.SourceDocumentOriginalState);
		FormItemSource = Form.Items.SourceDocumentOriginalState;
	Else
		RecordData = New Structure("Ref", Form.Object.Ref);
		Document = Form.Object.Ref;
		ShouldClarifyByPrintForms = True;
		FormItemSource = Source;
	EndIf;
	
	If Document.IsEmpty() Then
		ShowMessageBox(,NStr("vi = 'Để cài đặt trạng thái của bản gốc, trước tiên hãy kết chuyển chứng từ.';
							|ru = 'Для установки состояния оригинала предварительно проведите документ.';
							|en = 'To set the original state, post the document first.'; fa = 'To set the original state, post the document first.';
							|it = 'To set the original state, post the document first.';
							|pl = 'To set the original state, post the document first.';
							|tr = 'Orijinal durumu ayarlayabilmek için belgeyi kontrol edin.'"));
		Return;
	EndIf;

	Result = AttachableCommandsClient.DocsPostInfoRecords(
		CommonClientServer.ValueInArray(Document));
	If Result.UnpostedDocuments.Count() = 1 Then
		MessageText = ?(Result.HasPostingRight, 
			NStr("vi = 'Để cài đặt trạng thái của bản gốc, trước tiên hãy kết chuyển chứng từ.';
				|ru = 'Для установки состояния оригинала предварительно проведите документ.';
				|en = 'To set the original state, post the document first.'; fa = 'To set the original state, post the document first.';
				|it = 'To set the original state, post the document first.';
				|pl = 'To set the original state, post the document first.';
				|tr = 'Orijinal durumu ayarlayabilmek için belgeyi kontrol edin.'"),
			NStr("vi = 'Không thể thiết lập trạng thái của bản gốc, bởi vì không có quyền để kết chuyển chứng từ.';
				|ru = 'Невозможно установить состояние оригинала, т.к. нет прав на проведение документа.';
				|en = 'Cannot set the original state; insufficient rights to post the document.'; fa = 'Cannot set the original state; insufficient rights to post the document.';
				|it = 'Cannot set the original state; insufficient rights to post the document.';
				|pl = 'Cannot set the original state; insufficient rights to post the document.';
				|tr = 'Orijinal belgenin durumu tespit edilemez, çünkü belgeyi muhafaza etme yetkisi mevcut değil.'"));
		ShowMessageBox(, MessageText);
		Return;
	EndIf;
	
	ClientRunParameters = StandardSubsystemsClient.ClientRunParameters();
	OpenForm = Not ClientRunParameters.SourceDocumentsOriginalsRecording.ShouldOpenDropDownMenuFromHyperlink; 
	If OpenForm Then
		OpenPrintFormsStatesChangeForm(Document);
		Return;
	EndIf;

	ClarifyByPrintForms = Form.OriginalStatesChoiceList.FindByValue("ClarifyByPrintForms");
	If ShouldClarifyByPrintForms Then
		If ClarifyByPrintForms = Undefined Then
			Form.OriginalStatesChoiceList.Add("ClarifyByPrintForms",
				NStr("vi = 'Làm rõ theo mẫu in...';
					|ru = 'Уточнить по печатным формам...';
					|en = 'Specify for print forms…'; fa = 'Specify for print forms…';
					|it = 'Stabilire in base ai moduli stampati...';
					|pl = 'Uściślij wg formularzy wydruku...';
					|tr = 'Yazdırma formlarına göre netleştir...'"),,
				PictureLib.SetSourceDocumentOriginalStateByPrintForms);
		EndIf;
	ElsIf ClarifyByPrintForms <> Undefined Then
		Form.OriginalStatesChoiceList.Delete(ClarifyByPrintForms);
	EndIf;

	CallbackDescription = New CallbackDescription("OpenStateSelectionMenuCompletion", ThisObject, RecordData);
	Form.ShowChooseFromMenu(CallbackDescription, Form.OriginalStatesChoiceList, FormItemSource);

EndProcedure

// A notification handler of the "Source document tracking" subsystem events for the document form.
//
//	Parameters:
//  EventName - String - a name of the event that occurred.
//  Form - ClientApplicationForm - a document form. 
//   Source - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - Reference to the document (event trigger).
//            - Array of DefinedType.ObjectWithSourceDocumentsOriginalsAccounting:
//         * Ref - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - Reference to the document (event trigger).
//
Procedure NotificationHandlerDocumentForm(EventName, Form, Source = Undefined) Export
		
	If EventName = "Write_InformationRegisterSourceDocumentsOriginalsStates" 
		And ((TypeOf(Source) = Type("Array") And Source.Find(Form.Object.Ref) <> Undefined)
		Or Source = Undefined Or Source = Form.Object.Ref) Then 
		UpdateOriginalCurrentStateOnDocumentForm(Form);
	ElsIf EventName = "Write_SourceDocumentsOriginalsStates" Then	
		SubmenuOriginalState = Form.Items.Find("SetConfigureOriginalStateSubmenu");
		If SubmenuOriginalState <> Undefined Then
			Form.DetachIdleHandler("Attachable_UpdateOriginalStateCommands");
			Form.AttachIdleHandler("Attachable_UpdateOriginalStateCommands", 0.2, True);
			ConfigureButtonsOnDocumentForm(Form);
		EndIf;
		TheStructureOfTheSearch = New Structure;
 		TheStructureOfTheSearch.Insert("OriginalStatesChoiceList", Undefined);
 		FillPropertyValues(TheStructureOfTheSearch, Form);
 		If TheStructureOfTheSearch.OriginalStatesChoiceList <> Undefined Then
			SourceDocumentsOriginalsRecordingServerCall.FillOriginalStatesChoiceList(Form.OriginalStatesChoiceList); 
		EndIf;
		Form.RefreshDataRepresentation();	
	EndIf;
		
EndProcedure

// A notification handler of the "Source document tracking" subsystem events for the list form.
//
//	Parameters:
//  EventName - String - a name of the event that occurred.
//  Form - ClientApplicationForm - a list form of documents.
//  List - FormTable - the main form list.
//  Source - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - Reference to the document (event trigger).
//           - Array of DefinedType.ObjectWithSourceDocumentsOriginalsAccounting:
//         * Ref - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - Reference to the document (event trigger).
//
Procedure NotificationHandlerListForm(EventName, Form, List, Source = Undefined) Export 
	
	If EventName = "Write_SourceDocumentsOriginalsStates" Then
		TheStructureOfTheSearch = New Structure;
 		TheStructureOfTheSearch.Insert("OriginalStatesChoiceList", Undefined);
 		FillPropertyValues(TheStructureOfTheSearch, Form);
 		If TheStructureOfTheSearch.OriginalStatesChoiceList<> Undefined Then
			Form.DetachIdleHandler("Attachable_UpdateOriginalStateCommands");
			Form.AttachIdleHandler("Attachable_UpdateOriginalStateCommands", 0.2, True);
			SourceDocumentsOriginalsRecordingServerCall.FillOriginalStatesChoiceList(Form.OriginalStatesChoiceList);
			Form.RefreshDataRepresentation();
		Else
			Return;
		EndIf;
	ElsIf EventName = "Write_InformationRegisterSourceDocumentsOriginalsStates" Then
		List.Refresh();
	EndIf;

EndProcedure

// Handler of the "Choice" list event.
//
//	Parameters:
//  FieldName - String - a description of the selected field.
//  Form - ClientApplicationForm - a list form of documents.
//  List - FormTable - the main form list.
//  StandardProcessing - Boolean - True if standard processing of the "Choice" event is used in the form
//
Procedure ListSelection(FieldName, Form, List, StandardProcessing) Export 
	
	If FieldName = "SourceDocumentOriginalState" Or FieldName = "StateOriginalReceived" Then
		StandardProcessing = False;
		If SourceDocumentsOriginalsRecordingServerCall.IsAccountingObject(List.CurrentData.Ref) Then
			If FieldName = "SourceDocumentOriginalState" Then
				OpenStateSelectionMenu(Form, List);
			ElsIf FieldName = "StateOriginalReceived" Then
				SetOriginalState("SettingStateOriginalReceived", Form, List);
			EndIf;
		Else
			ShowMessageBox(, NStr("vi = 'Chứng từ này không ghi nhận bản gốc.';
									|ru = 'Для данного документа учет оригиналов не ведется.';
									|en = 'Records of originals are not kept for this document.'; fa = 'Records of originals are not kept for this document.';
									|it = 'Per questo documento non vengono registrati gli originali.';
									|pl = 'Dla danego dokumentu nie jest prowadzona ewidencja oryginałów.';
									|tr = 'Bu belge için asılların kaydı tutulmaz.'"));
		EndIf;
	EndIf;
	
EndProcedure

// The procedure processes actions of originals recording after scanning the document barcode.
//
//	Parameters:
//  Barcode - String - the scanned document barcode.
//  EventName - String - a form event name.
//
Procedure ProcessBarcode(Barcode, EventName) Export
	
	If EventName = "ScanData" Then
		Status(NStr("vi = 'Đặt trạng thái bản gốc theo mã vạch...';
					|ru = 'Выполняется установка состояния оригинала по штрихкоду...';
					|en = 'Setting original state by barcode…'; fa = 'Setting original state by barcode…';
					|it = 'Impostazione dello stato di originale in base al codice a barre in corso...';
					|pl = 'Trwa ustawienie statusu oryginału wg kodu kreskowego...';
					|tr = 'Aslın durumu barkoda göre belirleniyor...'"));
		SourceDocumentsOriginalsRecordingServerCall.ProcessBarcode(Barcode[0]);
	EndIf;
	
EndProcedure

// The procedure displays a notification about changing a document original state to the user.
//
//	Parameters:
//  ProcessedItemsCount - Number - a number of successfully processed documents.
//  Document - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - Reference to the document for processing the user notification click 
//			   in case of the single state setting. Optional parameter.
//  OriginalState - CatalogRef.SourceDocumentsOriginalsStates - Reference to the state to apply.
//
Procedure NotifyUserOfStatesSetting(ProcessedItemsCount, Document = Undefined, OriginalState = Undefined) Export

	If ProcessedItemsCount > 1 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã thiết lập trạng thái của bản gốc ""%1"" cho tất cả chứng từ được chọn trong danh sách.';
				|ru = 'Состояние оригинала ""%1"" установлено для всех выделенных в списке документов.';
				|en = 'The original state ""%1"" is applied to all selected documents.'; fa = 'The original state ""%1"" is applied to all selected documents.';
				|it = 'The original state ""%1"" is applied to all selected documents.';
				|pl = 'The original state ""%1"" is applied to all selected documents.';
				|tr = 'Listede vurgulanan tüm belgeler için orijinal durum, ""%1"" olarak ayarlanır.'"), String(OriginalState));
		
		TitleText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã thiết lập ""%1""';
				|ru = '""%1"" установлено';
				|en = '""%1"" is applied'; fa = '""%1"" is applied';
				|it = '""%1"" is applied';
				|pl = '""%1"" is applied';
				|tr = '""%1"" ayarlandı'"), String(OriginalState));

		ShowUserNotification(TitleText,, MessageText, PictureLib.DialogInformation, UserNotificationStatus.Information);
	Else
		CallbackDescription = New CallbackDescription("ProcessNotificationClick", ThisObject, Document);
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã thiết lập ""%1"":';
				|ru = '""%1"" установлено:';
				|en = '""%1"" is applied:'; fa = '""%1"" is applied:';
				|it = '""%1"" is applied:';
				|pl = '""%1"" is applied:';
				|tr = '""%1"" ayarlandı:'"), String(OriginalState));
		ShowUserNotification(MessageText, CallbackDescription, Document, PictureLib.DialogInformation,
			UserNotificationStatus.Information);
	EndIf;

EndProcedure

// Opens a list form of the "SourceDocumentsOriginalsStates" catalog.
Procedure OpenStatesSetupForm() Export
	
	OpenForm("Catalog.SourceDocumentsOriginalsStates.ListForm");

EndProcedure

// Called to record original states of print forms to the register after printing the form.
//
//	Parameters:
//  PrintObjects - ValueList - a list of references to print objects.
//  PrintList - ValueList - a list with template names and print form presentations.
//  Written1 - Boolean - indicates that the document state is written to the register.
//
Procedure WriteOriginalsStatesAfterPrint(PrintObjects, PrintList, Written1 = False) Export

	SourceDocumentsOriginalsRecordingServerCall.WriteOriginalsStatesAfterPrintingForms(PrintObjects, PrintList, Written1);
	If PrintList.Count() = 0 Or Written1 = False Then
		Return;
	EndIf;

	Notify("Write_InformationRegisterSourceDocumentsOriginalsStates",, PrintObjects.UnloadValues());
	
	If PrintObjects.Count() > 1 Then
		NotifyUserOfStatesSetting(PrintObjects.Count(),,PredefinedValue("Catalog.SourceDocumentsOriginalsStates.FormPrinted"));
	ElsIf PrintObjects.Count() = 1 Then
		NotifyUserOfStatesSetting(1,PrintObjects[0].Value,PredefinedValue("Catalog.SourceDocumentsOriginalsStates.FormPrinted"));
	EndIf;
	
EndProcedure

// Opens a form to refine states of the document print forms.
//
//	Parameters:
//  DocumentRef - DefinedType.ObjectWithSourceDocumentsOriginalsAccounting - Reference to the document for which the record key 
//  				 of the aggregated state must be received.
//
Procedure OpenPrintFormsStatesChangeForm(DocumentRef) Export

	RegisterRecordKey = SourceDocumentsOriginalsRecordingServerCall.OverallStateRecordKey(DocumentRef);
	
	TransmittedParameters = New Structure;
	If RegisterRecordKey = Undefined Then
		TransmittedParameters.Insert("DocumentRef", DocumentRef);
	Else
		TransmittedParameters.Insert("Key", RegisterRecordKey);
	EndIf;
	OpenForm("InformationRegister.SourceDocumentsOriginalsStates.Form.SourceDocumentsOriginalsStatesChange",
		TransmittedParameters);

EndProcedure

// Called when opening the source document originals journal if peripheral equipment is used.
// Allows you to define a custom process of connecting the peripheral equipment to the journal.
//	
//	Parameters:
//  Form - ClientApplicationForm - a document list form.
//
Procedure OnConnectBarcodeScanner(Form) Export
	
	SSLSubsystemsIntegrationClient.OnAttachBarcodeScannerToOriginalsRecordingJournal(Form);
	SourceDocumentsOriginalsRecordingClientOverridable.OnConnectBarcodeScanner(Form);

EndProcedure

#EndRegion

#Region Private

Procedure SetOriginalStateListForm(Parameters, List)	
	
	RowsArray = New Array; // See SourceDocumentsOriginalsRecordingServerCall.SetNewOriginalState.WritingObjects
	For Each ListLine In List.SelectedRows Do
		RowData = List.RowData(ListLine);
		RowsArray.Add(RowData);
	EndDo;

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("RowsArray", RowsArray);
	AdditionalParameters.Insert("Plural_Update", True);
	
	If Parameters.CommandDetails.Id = "StatesSetup" Then
		OpenStatesSetupForm();
		Return;
	EndIf;
	
	OriginalState = Parameters.CommandDetails.AdditionalParameters.RefToState;

	AdditionalParameters.Insert("OriginalState", OriginalState);
	
	If RowsArray.Count() > 1 Then
		QueryText = NStr("vi = 'Các chứng từ được chọn trong danh sách sẽ đặt trạng thái bản gốc ""%StateName%"". Tiếp tục?';
						|ru = 'У выделенных в списке документов будет установлено состояние оригинала ""%StateName%"". Продолжить?';
						|en = 'The ""%StateName%"" original state will be set for documents selected in the list. Continue?'; fa = 'The ""%StateName%"" original state will be set for documents selected in the list. Continue?';
						|it = 'Per i documenti selezionati dall''elenco verrà impostato lo stato dell''originale ""%StateName%"". Continuare?';
						|pl = 'Dla wybranych na liście dokumentów będzie ustawiony status oryginału ""%StateName%"". Kontynuować?';
						|tr = 'Listede seçilen belgeler için aslın durumu ""%StateName%"" olarak belirlenecektir. Devam edilsin mi?'");
		QueryText = StrReplace(QueryText, "%StateName%", String(OriginalState));

		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes,NStr("vi = 'Thiết lập';
												|ru = 'Установить';
												|en = 'Apply'; fa = 'اعمال';
												|it = 'Impostare';
												|pl = 'Apply';
												|tr = 'Ayarla'"));
		Buttons.Add(DialogReturnCode.No,NStr("vi = 'Không thiết lập';
											|ru = 'Не устанавливать';
											|en = 'Do not set'; fa = 'Do not set';
											|it = 'Non installare';
											|pl = 'Nie ustawiać';
											|tr = 'Belirleme'"));
		ShowQueryBox(New CallbackDescription("SetOriginalStateCompletion", ThisObject, AdditionalParameters), QueryText, Buttons); 
		
	ElsIf SourceDocumentsOriginalsRecordingServerCall.IsAccountingObject(RowsArray[0].Ref) Then 
		SetOriginalStateCompletion(DialogReturnCode.Yes, AdditionalParameters);
	Else
		ShowMessageBox(, NStr("vi = 'Chứng từ này không ghi nhận bản gốc.';
								|ru = 'Для данного документа учет оригиналов не ведется.';
								|en = 'Records of originals are not kept for this document.'; fa = 'Records of originals are not kept for this document.';
								|it = 'Per questo documento non vengono registrati gli originali.';
								|pl = 'Dla danego dokumentu nie jest prowadzona ewidencja oryginałów.';
								|tr = 'Bu belge için asılların kaydı tutulmaz.'"));
	EndIf;
	
EndProcedure

Procedure SetOriginalStateDocumentForm(Ref, Parameters)
			
	If Parameters.CommandDetails.Id = "StatesSetup" Then
		OpenStatesSetupForm();
	ElsIf Parameters.CommandDetails.Id = "ClarifyByPrintForms" Then
		OpenPrintFormsStatesChangeForm(Ref);
	Else
		OriginalState = Parameters.CommandDetails.AdditionalParameters.RefToState;
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("OriginalState", OriginalState); 
		AdditionalParameters.Insert("Ref", Ref);
		AdditionalParameters.Insert("Plural_Update", False);
		SetOriginalStateCompletion(DialogReturnCode.Yes, AdditionalParameters);
	EndIf;
	
EndProcedure

// Generates a label to display the current state information on a document form.
//
//	Parameters:
//  Form - ClientApplicationForm - Document form.
//
Procedure UpdateOriginalCurrentStateOnDocumentForm(Form)
	
	ConfigureButtonsOnDocumentForm(Form);

	OriginalStateDecoration = Form.Items.Find("OriginalStateDecoration");
	If OriginalStateDecoration = Undefined Then
		Return;
	EndIf;
		 
	If ValueIsFilled(Form.Object.Ref) Then
		CurrentOriginalState = SourceDocumentsOriginalsRecordingServerCall.OriginalStateInfoByRef(Form.Object.Ref);
		If CurrentOriginalState.Count() = 0 Then
			CurrentOriginalState=NStr("vi = '<Trạng thái bản gốc không xác định>';
										|ru = '<Состояние оригинала неизвестно>';
										|en = '<Original state is unknown>'; fa = '<Original state is unknown>';
										|it = '<Stato dell''originale sconosciuto>';
										|pl = '<Status oryginału nie jest znany>';
										|tr = '<Aslın durumu bilinmiyor>'");
			OriginalStateDecoration.TextColor = WebColors.Silver;
		Else
			CurrentOriginalState = CurrentOriginalState.SourceDocumentOriginalState;
			OriginalStateDecoration.TextColor = New Color;
		EndIf;
	Else
		OriginalStateDecoration.TextColor = WebColors.Silver;
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
		InformationRecords = SourceDocumentsOriginalsRecordingServerCall.OriginalStateInfoByRef(Form.Object.Ref);
		If Not InformationRecords.Count() = 0 Then 
			CurrentOriginalState = InformationRecords.SourceDocumentOriginalState;
			Picture = ?(CurrentOriginalState = PredefinedValue("Catalog.SourceDocumentsOriginalsStates.OriginalReceived"),
			PictureLib.SourceDocumentOriginalStateOriginalReceived,
			PictureLib.SourceDocumentOriginalStateOriginalNotReceived);
			SubmenuOriginalState.Representation = ButtonRepresentation.PictureAndText;
			SubmenuOriginalState.Title = CurrentOriginalState;
			SubmenuOriginalState.Picture = Picture;
		EndIf;
	EndIf;

EndProcedure

// Handler of the notification that was called after completing the SetOriginalState(…) procedure.
Procedure SetOriginalStateCompletion(Response, AdditionalParameters) Export

	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	OriginalState = AdditionalParameters.OriginalState;
	
	ReferencesArrray = New Array;
	If AdditionalParameters.Plural_Update Then
		WritingObjects = AdditionalParameters.RowsArray;
		For Each Object In WritingObjects Do
			ReferencesArrray.Add(Object.Ref);
		EndDo;
	Else
 		WritingObjects = AdditionalParameters.Ref;
		ReferencesArrray.Add(AdditionalParameters.Ref);
	EndIf;
	
	IsChanged = SourceDocumentsOriginalsRecordingServerCall.SetNewOriginalState(WritingObjects, OriginalState);
	If IsChanged = "NotConducted" Then
		ShowMessageBox(, NStr("vi = 'Để thiết lập trạng thái của các bản gốc, trước hết hãy kết chuyển chứng từ được chọn.';
								|ru = 'Для установки состояния оригиналов предварительно проведите выделенные документы.';
								|en = 'To set the original state, post the selected documents first.'; fa = 'To set the original state, post the selected documents first.';
								|it = 'Для установки состояния оригиналов предварительно проведите выделенные документы.';
								|pl = 'To set the original state, post the selected documents first.';
								|tr = 'Asılların durumunu yapılandırmak için vurgulanan belgeleri ön izleyin.'"));
		Return;
	ElsIf IsChanged = "NotIsChanged" Then
		Return;
	EndIf;

	If Not TypeOf(WritingObjects) = Type("Array") Then
		NotifyUserOfStatesSetting(1, WritingObjects, OriginalState); 
	ElsIf WritingObjects.Count() = 1 Then 
		NotifyUserOfStatesSetting(1, WritingObjects[0].Ref, OriginalState);
	Else
		NotifyUserOfStatesSetting(WritingObjects.Count(), , OriginalState);
	EndIf;
	
	Notify("Write_InformationRegisterSourceDocumentsOriginalsStates",, ReferencesArrray);

EndProcedure

// Handler of the notification that was called after completing the OpenStateSelectionMenu(…) procedure.
//	
//	Parameters:
//  SelectedStateFromList - String - the original state selected by the user.
//  AdditionalParameters - Structure - information required to set the original state:
//                            * Ref - DocumentRef - a reference to a document to set the original state.
//       	                - Array of DocumentRef:
//                            * Ref - DocumentRef - a reference to a document to set the original state.
//
Procedure OpenStateSelectionMenuCompletion(SelectedStateFromList, AdditionalParameters) Export

	If SelectedStateFromList = Undefined Then
		Return;
	EndIf;

	Ref = AdditionalParameters.Ref;
	If TypeOf(AdditionalParameters) = Type("FormDataStructure") Then 
		RecordData = New Array;
		RecordData.Add(AdditionalParameters);  
	Else
		RecordData = AdditionalParameters.Ref;
	EndIf;
			
	If SelectedStateFromList.Value = "ClarifyByPrintForms" Then
		OpenPrintFormsStatesChangeForm(Ref);
		Return;
	EndIf;
	
	IsChanged = SourceDocumentsOriginalsRecordingServerCall.SetNewOriginalState(RecordData, 
		SelectedStateFromList.Value);
	If IsChanged = "IsChanged" Then
		NotifyUserOfStatesSetting(1, Ref, SelectedStateFromList.Value);
		Notify("Write_InformationRegisterSourceDocumentsOriginalsStates",, Ref);
	ElsIf IsChanged = "NotConducted" Then
		ShowMessageBox(, NStr("vi = 'Để cài đặt trạng thái của bản gốc, trước tiên hãy kết chuyển chứng từ được chọn.';
								|ru = 'Для установки состояния оригиналов предварительно проведите выделенные документы.';
								|en = 'To set the original state, post the selected documents first.'; fa = 'To set the original state, post the selected documents first.';
								|it = 'Для установки состояния оригиналов предварительно проведите выделенные документы.';
								|pl = 'To set the original state, post the selected documents first.';
								|tr = 'Asılların durumunu yapılandırmak için vurgulanan belgeleri ön izleyin.'"));
	EndIf;

EndProcedure

// Handler of the notification that was called after completing the NotifyUserOfStatesSetting(…) procedure.
Procedure ProcessNotificationClick(AdditionalParameters) Export

	ShowValue(,AdditionalParameters);

EndProcedure

#EndRegion
