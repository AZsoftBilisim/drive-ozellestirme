
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	LoadList(Cancel);
	SetTitleProgrammatically();
	DoImportParameters();
	
	TypesList = New Array;
	For Each Item In DocumentsList Do
		TypesList.Add(TypeOf(Item.Value));
	EndDo;
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(TypesList);
	PlacementParameters.CommandBar = Items.ListCreatedDocumentsCommandBar;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not CloseWithoutConfirmation Then
		
		StandardProcessing = False;
		Cancel = True;
		If Exit Then
			WarningText = NStr("vi = 'Đã thay đổi dữ liệu. Tất cả thay đổi sẽ bị mất.';
								|ru = 'Данные были изменены. Все изменения будут потеряны.';
								|en = 'All changes made to the data will be lost.'; fa = 'All changes made to the data will be lost.';
								|it = 'I dati sono stati modificati. Tutte le modifiche verranno perse.';
								|pl = 'Dane zostały zmienione. Wszystkie zmiany zostaną utracone.';
								|tr = 'Veri değişti. Tüm değişiklikler kaybolacak.'");
			Return;
		EndIf;
		
		Buttons = New ValueList();
		Buttons.Add(DialogReturnCode.OK, NStr("vi = 'Đóng';
												|ru = 'Закрыть';
												|en = 'Close'; fa = 'بستن';
												|it = 'Chiudere';
												|pl = 'Zamknij';
												|tr = 'Kapat'"));
		Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Anuluj';
													|tr = 'İptal'"));
		
		QueryText = NStr("vi = 'Làm việc với các chứng từ được tạo ra chưa được hoàn thành. Đóng mẫu?';
						|ru = 'Работа с созданными документами не была завершена. Закрыть форму?';
						|en = 'Work with created documents was not completed. Close the form?'; fa = 'Work with created documents was not completed. Close the form?';
						|it = 'Il lavoro con i documenti creati non è stato completato. Chiudere il modulo?';
						|pl = 'Praca z utworzonymi dokumentami nie została zakończona. Zamknąć formularz?';
						|tr = 'Oluşturulan belgelerle ilgili çalışma tamamlanmadı. Form kapatılsın mı?'");
		
		ShowQueryBox(New CallbackDescription("QuestionOfClosure", ThisObject), QueryText, Buttons);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If UpdateEvents.FindByValue(EventName) <> Undefined Then
		
		Items.ListCreatedDocuments.Refresh();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListCreatedDocuments

&AtClient
Procedure ListCreatedDocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListCreatedDocumentsOnActivateRow(Item)
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
EndProcedure

&AtClient
Procedure ListCreatedDocumentsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListCreatedDocumentsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.SetDeletionMark(Item, Title);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.ListCreatedDocuments);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.ListCreatedDocuments, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ListCreatedDocuments);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure BackCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	If CreatedDocumentsDeleted() Then
		CloseWithoutConfirmation = True;
		Notify("Accept_FormOfCreatedDocuments", NotificationProcessingParameter(False), ThisObject);
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure Back(Command)
	Buttons = New ValueList();
	Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Đặt dấu xóa chứng từ';
											|ru = 'Пометить документы на удаление';
											|en = 'Mark documents for deletion'; fa = 'علامت‌گذاری اسناد برای حذف';
											|it = 'Contrassegnare i documenti per l''eliminazione';
											|pl = 'Zaznacz dokumenty do usunięcia';
											|tr = 'Silinmek için belgeleri işaretle'"));
	Buttons.Add(DialogReturnCode.Cancel);
	
	QueryText = NStr("vi = 'Các chứng từ được tạo sẽ được đánh dấu để xóa.';
					|ru = 'Сформированные документы будут помечены на удаление.';
					|en = 'Generated documents will be marked for deletion.'; fa = 'Generated documents will be marked for deletion.';
					|it = 'I documenti generati saranno contrassegnati per l''eliminazione.';
					|pl = 'Utworzone dokumenty będą zaznaczone do usunięcia.';
					|tr = 'Oluşturulan belgeler silinmek için işaretlenecektir.'");
	
	ShowQueryBox(New CallbackDescription("BackCompletion", ThisObject), QueryText, Buttons);
EndProcedure

&AtClient
Procedure Accept(Command)
	QuestionUnverifiedDocuments();
EndProcedure

&AtClient
Procedure Post(Command)
	TMCommonUseClient.PostDocuments(Items.ListCreatedDocuments, Title);
EndProcedure

&AtClient
Procedure UndoPosting(Command)
	TMCommonUseClient.UndoPosting(Items.ListCreatedDocuments, Title);
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure LoadList(Cancel)
	
	CreatedDocumentsInSecureStorage = Parameters.CreatedDocuments = Undefined;
	
	If CreatedDocumentsInSecureStorage Then
		CreatedDocuments = ReadDataFromSecureStorage(Parameters.DataKey);
	Else
		CreatedDocuments = New Array;
		For Each SDElement In Parameters.CreatedDocuments Do
			CreatedDocuments.Add(SDElement.Document);
		EndDo;
	EndIf;
	
	If Not ValueIsFilled(CreatedDocuments) Then
		Raise NStr("vi = 'Một ngoại lệ xảy ra trong khi tạo chứng từ.';
					|ru = 'Произошла исключительная ситуация при создании документов.';
					|en = 'An exception is thrown when generating documents.'; fa = 'An exception is thrown when generating documents.';
					|it = 'Si è verificata una situazione eccezionale durante la creazione di documenti.';
					|pl = 'Wystąpiła sytuacja wyjątkowa podczas tworzenia dokumentów.';
					|tr = 'Belgelerin oluşturulması sırasında istisnai bir durum meydana geldi.'");
		Cancel = True;
	ElsIf CreatedDocumentsInSecureStorage Then
		DeleteDataFromSecureStorage();
	EndIf;
	
	DocumentsList.LoadValues(CreatedDocuments);
	
	CommonClientServer.SetDynamicListFilterItem(
		ListCreatedDocuments,
		"Ref",
		CreatedDocuments,
		DataCompositionComparisonType.InList,
		,
		True);
	
EndProcedure

&AtServer
Procedure SetTitleProgrammatically()
	
	DocumentsCount = DocumentsList.Count();
	
	DeclensionIsCreated = NStr("vi = 'Đã tạo mới, Đã tạo mới, Đã tạo mới';
								|ru = 'Создан, Создано, Создано';
								|en = 'Created, Created, Created'; fa = 'Created, Created, Created';
								|it = 'Creato, Creato, Creato';
								|pl = 'Utworzony, Utworzono, Utworzono';
								|tr = 'Oluşturuldu, Oluşturuldu, Oluşturuldu'");
	CreatedOn = StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(DocumentsCount, DeclensionIsCreated);
	CreatedOn = StrReplace(CreatedOn, DocumentsCount + " ", "");
	
	DeclinationOfDocuments = NStr("vi = 'chứng từ, chứng từ, chứng từ';
									|ru = 'документ, документа, документов';
									|en = 'document, document, documents'; fa = 'document, document, documents';
									|it = 'documento, documento, documenti';
									|pl = 'dokument, dokumentu, dokumentów';
									|tr = 'belge, belgenin, belgeler'");
	Var_Documents = StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(DocumentsCount, DeclinationOfDocuments);
	
	Title = CreatedOn + " " + Var_Documents;
	
EndProcedure

&AtServer
Procedure DoImportParameters()
	
	For Each Column In Items.ListCreatedDocuments.ChildItems Do
		If Column <> Items.OperationGroupType Then
			Column.Visible = Parameters.VisibleColumns.Find(Column.Name) <> Undefined;
		EndIf;
	EndDo;
	UpdateEvents.LoadValues(Parameters.UpdateEvents);
	
EndProcedure

&AtClient
Procedure QuestionOfClosure(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.Cancel Then
		Return;
	ElsIf Response = DialogReturnCode.OK Then
		QuestionUnverifiedDocuments();
	EndIf;
	
EndProcedure

&AtClient
Function NotificationProcessingParameter(ReturnOwnerId)
	
	If TypeOf(FormOwner) = Type("ClientApplicationForm") And ReturnOwnerId Then
		IdOfOwnerSForm = FormOwner.UUID;
	Else
		IdOfOwnerSForm = Undefined;
	EndIf;
	Return New Structure("IdOfOwnerSForm", IdOfOwnerSForm);
	
EndFunction

&AtClient
Procedure QuestionUnverifiedDocuments()
	If HasUnpostedDocuments() Then
		Buttons = New ValueList();
		Buttons.Add(DialogReturnCode.Yes);
		Buttons.Add(DialogReturnCode.No);
		
		QueryText = NStr("vi = 'Chưa kết chuyển một số chứng từ. Bạn có chắc chắn muốn để lại chứng từ chưa kết chuyển?';
						|ru = 'Некоторые документы не были проведены. Вы уверены, что хотите оставить документы непроведенными?';
						|en = 'Some documents were not posted. Are you sure you want to leave the documents unposted?'; fa = 'Some documents were not posted. Are you sure you want to leave the documents unposted?';
						|it = 'Alcuni documenti non sono stati registrati. Siete sicuri di voler lasciare i documenti non registrati?';
						|pl = 'Niektóre dokumenty nie zostały zaksięgowane. Czy na pewno chcesz zostawić dokumenty bez zaksięgowania?';
						|tr = 'Bazı belgeler yerine getirilmemiştir. Belgeleri kaydetmeden bırakmak istediğinizden emin misiniz?'");
		ShowQueryBox(New CallbackDescription("QuestionAboutClosingUnverifiedDocuments", ThisObject), QueryText, Buttons);
	Else
		CloseWithoutConfirmation = True;
		Notify("Accept_FormOfCreatedDocuments", NotificationProcessingParameter(True), ThisObject);
		If ThisForm.IsOpen() Then
			Close();
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure QuestionAboutClosingUnverifiedDocuments(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.No Then
		Return;
	ElsIf Response = DialogReturnCode.Yes Then
		CloseWithoutConfirmation = True;
		Notify("Accept_FormOfCreatedDocuments", NotificationProcessingParameter(True), ThisObject);
		Close();
	EndIf;
	
EndProcedure

&AtServer
Function HasUnpostedDocuments()
	
	Query = New Query("
	|SELECT ALLOWED TOP 1
	|	DocumentsRegistry.Ref
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	NOT DocumentsRegistry.Posted
	|	AND DocumentsRegistry.Ref IN (&DocumentsList)
	|");
	
	Query.SetParameter("DocumentsList", DocumentsList);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

&AtServer
Function CreatedDocumentsDeleted()

	ErrorList = TMCommonUse.SetMarkForDeletingDocuments(DocumentsList.UnloadValues());
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	TRUE AS Field1
		|FROM
		|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|WHERE
		|	DocumentsRegistry.Ref IN(&Ref)
		|		AND NOT DocumentsRegistry.DeletionMark";
	
	Query.SetParameter("Ref", DocumentsList.UnloadValues());
	
	If Query.Execute().IsEmpty() Then
		Return True;
	Else
		CommonClientServer.ReportErrorsToUser(ErrorList);
		Items.ListCreatedDocuments.Refresh();
		Return False;
	EndIf;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListCreatedDocuments.Date", "Date");
	
EndProcedure

#Region EnsuringDataSecurity

&AtServerNoContext
Function ReadDataFromSecureStorage(DataKey)
	
	Owner = Users.AuthorizedUser();
	SetPrivilegedMode(True);
	ProtectedData = Common.ReadDataFromSecureStorage(Owner, DataKey);
	SetPrivilegedMode(False);
	
	Return ProtectedData
	
EndFunction

&AtServerNoContext
Procedure DeleteDataFromSecureStorage()
	Owner = Users.AuthorizedUser();
	SetPrivilegedMode(True);
	Common.DeleteDataFromSecureStorage(Owner, "DocumentLogOfProcessingCreatedDocuments");
	SetPrivilegedMode(False);
EndProcedure

#EndRegion

#EndRegion