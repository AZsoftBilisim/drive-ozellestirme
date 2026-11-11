#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	CreatedDocuments = ReadDataFromSecureStorage();
	
	If Not ValueIsFilled(CreatedDocuments) Then
		Cancel = True;
		Raise NStr("vi = 'Một ngoại lệ xảy ra trong khi tạo chứng từ.';
					|ru = 'Произошла исключительная ситуация при создании документов.';
					|en = 'An exception is thrown when generating documents.'; fa = 'An exception is thrown when generating documents.';
					|it = 'Si è verificata una situazione eccezionale durante la creazione di documenti.';
					|pl = 'Wystąpiła sytuacja wyjątkowa podczas tworzenia dokumentów.';
					|tr = 'Belgeler düzenlenirken istisnai bir durum meydana geldi.'");
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Ref",
		CreatedDocuments,
		DataCompositionComparisonType.InList,
		,
		True);
	
	If Parameters.Property("ErrorList") Then
		For Each CurError In Parameters.ErrorList Do
			CommonClientServer.MessageToUser(CurError.ErrorText,
			CurError.Document);
		EndDo;
	EndIf;
	
	DeclensionOfWord = TMCommonUseClientServer.DeclensionOfWord(
		CreatedDocuments.Count(),
		NStr("vi = 'chứng từ, chứng từ, chứng từ, m';
			|ru = 'документ, документа, документов, м';
			|en = 'document, documents'; fa = 'document, documents';
			|it = 'документ, документа, документов, м';
			|pl = 'document, documents';
			|tr = 'belge, belgeler, belgeler, m'"));
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(
		Title,
		NStr("vi = 'Lập sản lượng nhân viên';
			|ru = 'Оформление выработки сотрудников';
			|en = 'Register timesheets charge'; fa = 'ثبت کارکرد';
			|it = 'Formalizzazione della produttività dei dipendenti';
			|pl = 'Rejestracja wydajności pracowników';
			|tr = 'Zaman çizelgesi bazlı ücretlendirmenin düzenlenmesi'"),
		CreatedDocuments.Count(),
		DeclensionOfWord);
	
	MetadataObjects = New Array;
	MetadataObjects.Add(Metadata.Documents.WorkOutput);
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = MetadataObjects;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not ClosingInProgress Then
		
		If Not Exit And DocumentsNotProcessed() Then
			
			Cancel = True;
		
			CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisForm);
			
			QuestionTitle = "";
			QueryText = NStr("vi = 'Danh sách chứa các chứng từ không được đăng, không được đánh dấu để xóa. Tiếp tục?';
							|ru = 'В списке присутствуют непроведенные, непомеченные на удаление документы. Продолжить?';
							|en = 'There are unposted documents and documents unmarked for deletion in the list. Continue?'; fa = 'There are unposted documents and documents unmarked for deletion in the list. Continue?';
							|it = 'L''elenco contiene documenti non registrati, non contrassegnati per la cancellazione. Continuare?';
							|pl = 'W liście są dokumenty niezatwierdzone, niezaznaczone do usunięcia. Kontynuować?';
							|tr = 'Listede, gönderilmemiş, silinmek üzere işaretlenmemiş belgeler bulunmaktadır. Devam edilsin mi?'");
			
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo,,, QuestionTitle)
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		DeleteDocuments();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region EventHandlersForPageElementsDesigned

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Item.CurrentData;
	If CurrentData <> Undefined Then
		DescriptionOfTheAlert = New CallbackDescription("UpdateListData", ThisForm);
		ShowValue(DescriptionOfTheAlert, Item.CurrentData.Ref);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure CloseCommand(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure EditDocumentList(Command)
	
	CurrentData = Items.List.CurrentData;
	If CurrentData <> Undefined Then
		ShowValue(Undefined, CurrentData.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOfDocumentsSetDeleteMark(Command)
	
	SelectedListLines = Items.List.SelectedRows;
	
	If SelectedListLines.Count() <> 0 Then
		
		SelectedRows = New Array; // Array of DocumentRef.WorkOutput
		
		For Each CurRow In SelectedListLines Do
			SelectedRows.Add(Items.List.RowData(CurRow).Ref);
		EndDo;
		
		HasItemsMarkedForDeletion = HasItemsMarkedForDeletion(SelectedRows);
		
		If SelectedRows.Count() = 1 Then
			Document = SelectedRows[0];
			QueryText = ?(HasItemsMarkedForDeletion, NStr("vi = 'Bỏ dấu xóa ""%1""?';
															|ru = 'Снять с ""%1"" пометку на удаление?';
															|en = 'Clear mark for deletion for ""%1""?'; fa = 'Clear mark for deletion for ""%1""?';
															|it = 'Rimuovere il contrassegno per cancellazione da ""%1""?';
															|pl = 'Usunąć z ""%1"" zaznaczenie do usunięcia?';
															|tr = '""%1"" için silme işareti kaldırılsın mı?'"),
			NStr("vi = 'Đặt dấu xóa ""%1""?';
				|ru = 'Пометить ""%1"" на удаление?';
				|en = 'Mark ""%1"" for deletion?'; fa = 'Mark ""%1"" for deletion?';
				|it = 'Contrassegnare ""%1"" per cancellazione?';
				|pl = 'Zaznaczyć ""%1"" do usunięcia?';
				|tr = '""%1"" silinmek üzere işaretlensin mi?'"));
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(QueryText, Document);
		Else
			QueryText = ?(HasItemsMarkedForDeletion, NStr("vi = 'Bỏ dấu xóa các đối tượng đã chọn?';
															|ru = 'Снять с выделенных элементов пометку на удаление?';
															|en = 'Unmark selected items for deletion?'; fa = 'Unmark selected items for deletion?';
															|it = 'Rimuovere il contrassegno per la cancellazione dagli elementi selezionati?';
															|pl = 'Usunąć z wybranych elementów zaznaczenie do usunięcia?';
															|tr = 'Belirtilen öğelerin silme işareti kaldırılsın mı?'"),
			NStr("vi = 'Đánh dấu xóa phần tử đã chọn?';
				|ru = 'Пометить выделенные элементы на удаление?';
				|en = 'Mark the selected items for deletion?'; fa = 'Mark the selected items for deletion?';
				|it = 'Contrassegnare gli elementi selezionati per la cancellazione?';
				|pl = 'Zaznaczyć wybrane elementy do usunięcia?';
				|tr = 'Belirtilen öğeler silinmek üzere işaretlensin mi?'"));
		EndIf;
		
		ListOfResponses = New ValueList;
		ListOfResponses.Add(DialogReturnCode.Yes, NStr("vi = 'Có';
														|ru = 'Да';
														|en = 'Yes'; fa = 'بله';
														|it = 'Sì';
														|pl = 'Tak';
														|tr = 'Evet'"));
		ListOfResponses.Add(DialogReturnCode.No, NStr("vi = 'Không';
														|ru = 'Нет';
														|en = 'No'; fa = 'خیر';
														|it = 'Non ci sono';
														|pl = 'Nie';
														|tr = 'Hayır'"));
		
		ShowQueryBox(New CallbackDescription("SetDeletionMarkCompletion", 
			ThisObject, 
			New Structure("SelectedRows, SetMarkForDeletion", SelectedRows, Not HasItemsMarkedForDeletion)), 
			QueryText, 
			ListOfResponses);
	EndIf;
		
EndProcedure

&AtClient
Procedure ListOfDocumentsCancellationOfTheEvent(Command)
	
	ClearMessages();
	
	SelectedRows = New Array; // Array of DocumentRef.WorkOutput
		
	For Each CurRow In Items.List.SelectedRows Do
		SelectedRows.Add(Items.List.RowData(CurRow).Ref);
	EndDo;
	
	ResultOfCarryingOut = PostDocuments(SelectedRows, False);
	
	DocumentsForProcessing = ResultOfCarryingOut.DocumentsForProcessing;
	NotProcessedDocuments = ResultOfCarryingOut.UnpostedDocuments;
	
	NotifyUserAboutDocuments(DocumentsForProcessing, NotProcessedDocuments, False);
	
	Items.List.Refresh();
	
EndProcedure

&AtClient
Procedure ListOfDocumentsToHold(Command)
	
	ClearMessages();
	
	SelectedRows = New Array; // Array of DocumentRef.WorkOutput
	
	For Each CurRow In Items.List.SelectedRows Do
		SelectedRows.Add(Items.List.RowData(CurRow).Ref);
	EndDo;
	
	ResultOfCarryingOut = PostDocuments(SelectedRows, True);
	
	DocumentsForProcessing = ResultOfCarryingOut.DocumentsForProcessing;
	NotProcessedDocuments = ResultOfCarryingOut.UnpostedDocuments;
	
	NotifyUserAboutDocuments(DocumentsForProcessing, NotProcessedDocuments, True);
	
	Items.List.Refresh();
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function ReadDataFromSecureStorage()
	Owner = Users.AuthorizedUser();
	SetPrivilegedMode(True);
	ProtectedData = Common.ReadDataFromSecureStorage(Owner, "EmployeeDevelopmentForm");
	SetPrivilegedMode(False);
	Return ProtectedData
EndFunction

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisForm, "List.Date", "Date");

EndProcedure

// Conducts documents
// 
// Parameters:
// 	SelectedRows - Array of DocumentRef.WorkOutput - array of documents
// 	Posting - Boolean - flag of the event
// Returns:
// 	Structure - LongDesc:
// * UnpostedDocuments - Array of Structure:
// ** Ref - DocumentRef.WorkOutput
// ** ErrorDescription - String
// * DocumentsForProcessing - Array
//
&AtServer
Function PostDocuments(SelectedRows, Posting = True)
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("DocumentsForProcessing");
	ReturnStructure.Insert("UnpostedDocuments");
	
	UnpostedDocuments = New Array();
	
	If SelectedRows.Count() = 0 Then
		ReturnStructure.DocumentsForProcessing = New Array();
		ReturnStructure.UnpostedDocuments = New Array();
		Return ReturnStructure;
	EndIf;
	
	DocumentsForProcessing = GeneralPurposeTMServerCall.DynamicListDocumentLinks(SelectedRows);
	
	If Posting Then
		UnpostedDocuments = Common.PostDocuments(DocumentsForProcessing);
	Else
		For Each CurRow In SelectedRows Do
			
			BeginTransaction();
			Try
				
				Block = New DataLock;
				
				LockItem = Block.Add("Document.WorkOutput");
				LockItem.SetValue("Ref", CurRow);
				LockItem.Mode = DataLockMode.Exclusive;
				
				Block.Lock();
				DocumentObject = CurRow.GetObject();
				DocumentObject.Write(DocumentWriteMode.UndoPosting);
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				DefaultLanguageCode = Common.DefaultLanguageCode();
				WriteLogEvent(
					NStr("vi = 'Lập sản lượng nhân viên';
						|ru = 'Оформление выработки сотрудников';
						|en = 'Register timesheets charge'; fa = 'ثبت کارکرد';
						|it = 'Formalizzazione della produttività dei dipendenti';
						|pl = 'Rejestracja wydajności pracowników';
						|tr = 'Zaman çizelgesi bazlı ücretlendirmenin düzenlenmesi'", DefaultLanguageCode)
						+ "." + NStr("vi = 'Kết chuyển văn bản';
									|ru = 'Проведение документов';
									|en = 'Document posting'; fa = 'ثبت سند';
									|it = 'Registrazione dei documenti';
									|pl = 'Zaksięgowanie dokumentów';
									|tr = 'Belgelerin kaydedilmesi'", DefaultLanguageCode),
					EventLogLevel.Error,,
					CurRow,
					DetailErrorDescription(ErrorInfo()));
				
				ErrorPresentation = BriefErrorDescription(ErrorInfo());
				
				ErrorDescription = New Structure;
				ErrorDescription.Insert("Ref", CurRow);
				ErrorDescription.Insert("ErrorDescription", ErrorPresentation);
				
				UnpostedDocuments.Add(ErrorDescription);
				
			EndTry;
			
		EndDo;
	EndIf;
	
	Items.List.Refresh();
	
	ReturnStructure.Insert("DocumentsForProcessing", DocumentsForProcessing);
	ReturnStructure.Insert("UnpostedDocuments", UnpostedDocuments);
	
	Return ReturnStructure;
	
EndFunction

&AtServer
Procedure DeleteDocuments()
	
	CreatedDocuments = ReadDataFromSecureStorage();
	
	If Not ValueIsFilled(CreatedDocuments) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	DD.Ref
		|FROM
		|	Document.WorkOutput AS DD
		|WHERE
		|	DD.Ref IN(&SelectedRows)
		|	AND DD.DeletionMark";
	
	Query.SetParameter("SelectedRows", CreatedDocuments);
	Selection = Query.Execute().Select();
	
	SetPrivilegedMode(True);
	
	While Selection.Next() Do
		
		BeginTransaction();
		Try
			Block = New DataLock;
			
			LockItem = Block.Add("Document.WorkOutput");
			LockItem.SetValue("Ref", Selection.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			DocumentObject = Selection.Ref.GetObject(); // DocumentObject.WorkOutput
			DocumentObject.Delete();
			CommitTransaction();
		Except
			RollbackTransaction();
			DefaultLanguageCode = Common.DefaultLanguageCode();
			WriteLogEvent(
				NStr("vi = 'Lập sản lượng nhân viên';
					|ru = 'Оформление выработки сотрудников';
					|en = 'Register timesheets charge'; fa = 'ثبت کارکرد';
					|it = 'Formalizzazione della produttività dei dipendenti';
					|pl = 'Rejestracja wydajności pracowników';
					|tr = 'Zaman çizelgesi bazlı ücretlendirmenin düzenlenmesi'", DefaultLanguageCode)
					+ "." + NStr("vi = 'Xóa chứng từ';
								|ru = 'Удаление документов';
								|en = 'Remove documents'; fa = 'Remove documents';
								|it = 'Cancellazione documenti';
								|pl = 'Usuwanie dokumentów';
								|tr = 'Belgelerin silinmesi'", DefaultLanguageCode),
				EventLogLevel.Error,,
				Selection.Ref,
				DetailErrorDescription(ErrorInfo()));
			
			ErrorPresentation = BriefErrorDescription(ErrorInfo());
			CommonClientServer.MessageToUser(ErrorPresentation, Selection.Ref);
		EndTry;
	EndDo;
	
EndProcedure

&AtClient
Procedure NotifyUserAboutDocuments(DocumentsForProcessing, DataOnUnprocessedDocuments, Posting)
	
	NotProcessedDocuments = New Array;
	
	MessageTemplate = ?(Posting, 
		NStr("vi = 'Chưa kết chuyển chứng từ %1: %2';
			|ru = 'Документ %1 не проведен: %2';
			|en = 'Document %1 is not posted: %2'; fa = 'Document %1 is not posted: %2';
			|it = 'Documento %1 non è registrato: %2';
			|pl = 'Dokument %1 nie jest zaksięgowany: %2';
			|tr = '%1 belgesi kaydedilmedi: %2'"),
		NStr("vi = 'Chứng từ %1 không thể hoàn thành: %2';
			|ru = 'Документ %1 не удалось сделать непроведенным: %2';
			|en = 'Cannot make document %1 unposted: %2'; fa = 'Cannot make document %1 unposted: %2';
			|it = 'Non è stato possibile rendere il documento %1 non registrato: %2';
			|pl = 'Dokument %1 nie udało się zrobić niezarejestrowanym: %2';
			|tr = '%1 belgesi kaydedilmemiş hale getirilemedi: %2'"));
	
	For Each DocumentInformation In DataOnUnprocessedDocuments Do
		CommonClientServer.MessageToUser(
			StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate,
				String(DocumentInformation.Ref),
				DocumentInformation.ErrorDescription),
			DocumentInformation.Ref);
		
		NotProcessedDocuments.Add(DocumentInformation.Ref);
	EndDo;
	
	If NotProcessedDocuments.Count() > 0 Then
		DialogText = ?(Posting, 
				NStr("vi = 'Không thể kết chuyển một hoặc nhiều văn bản.';
					|ru = 'Не удалось провести один или несколько документов.';
					|en = 'Cannot post one or several documents.'; fa = 'Cannot post one or several documents.';
					|it = 'Non è possibile registrare uno o più documenti.';
					|pl = 'Nie udało się zaksięgować jeden lub kilka dokumentów.';
					|tr = 'Bir veya birden fazla belge kaydedilemedi.'"),
				NStr("vi = 'Không thể thực hiện kết chuyển một hoặc nhiều chứng từ.';
					|ru = 'Не удалось сделать непроведенным один или несколько документов.';
					|en = 'Cannot make one or several documents unposted.'; fa = 'Cannot make one or several documents unposted.';
					|it = 'Non è stato possibile rendere non registrati uno o più documenti.';
					|pl = 'Nie udało się zrobić niezatwierdzonym jeden lub kilka dokumentów.';
					|tr = 'Bir veya daha fazla belge kaydedilmemiş hale getirilemedi.'"));

		ShowMessageBox(, DialogText);
	EndIf;

	ProcessedDocuments = CommonClientServer.ArraysDifference(DocumentsForProcessing, NotProcessedDocuments);
	
	If ProcessedDocuments.Count() > 0 Then
		
		If DocumentsForProcessing.Count() > 1 Then
			Document = Title;
			NotificationText1 = NStr("vi = 'Thay đổi (%DocumentsCount%)';
									|ru = 'Изменение (%DocumentsCount%)';
									|en = 'Change (%DocumentsCount%)'; fa = 'Change (%DocumentsCount%)';
									|it = 'Modifica (%DocumentsCount%)';
									|pl = 'Zmiana (%DocumentsCount%)';
									|tr = 'Değişim (%DocumentsCount%)'");
			NotificationText1 = StrReplace(NotificationText1, "%DocumentsCount%", ProcessedDocuments.Count());
			ActionOnClick = "";
		Else
			Document = DocumentsForProcessing[0];
			NotificationText1 = NStr("vi = 'Thay đổi';
									|ru = 'Изменение';
									|en = 'Update'; fa = 'به‌روزرسانی';
									|it = 'Modifica';
									|pl = 'Zmiana';
									|tr = 'Değişim'");
			ActionOnClick = GetURL(Document);
		EndIf;
		
		ShowUserNotification(NotificationText1, ActionOnClick, String(Document),
			PictureLib.Information32);
		
	EndIf;

EndProcedure

&AtServer
Function HasItemsMarkedForDeletion(SelectedRows)
	
	Query = New Query;
	Query.Text =
		"SELECT TOP 1
		|	DD.Ref
		|FROM
		|	Document.WorkOutput AS DD
		|WHERE
		|	DD.Ref IN(&SelectedRows)
		|	AND DD.DeletionMark";
		
	Query.SetParameter("SelectedRows", SelectedRows);
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
	
EndFunction

&AtClient
Procedure SetDeletionMarkCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		ReferencesArrray = AdditionalParameters.SelectedRows;
		MarkToDelete = AdditionalParameters.SetMarkForDeletion;
		
		SetDeletionMarkCompletionServer(AdditionalParameters);
		
		If ReferencesArrray.Count() > 1 Then
			Document = ReferencesArrray[0];
			NotificationText1 = ?(Not MarkToDelete, 
				NStr("vi = 'Bỏ đặt dấu xóa (%DocumentsCount%)';
					|ru = 'Пометка удаления снята (%DocumentsCount%)';
					|en = 'Deletion mark is cleared (%DocumentsCount%)'; fa = 'Deletion mark is cleared (%DocumentsCount%)';
					|it = 'Il contrassegno per la cancellazione è stato rimosso (%DocumentsCount%)';
					|pl = 'Usunięto zaznaczenie usunięcia (%DocumentsCount%)';
					|tr = 'Silme işareti kaldırıldı (%DocumentsCount%)'"),
				NStr("vi = 'Đã đặt dấu xóa (%DocumentsCount%)';
					|ru = 'Пометка удаления установлена (%DocumentsCount%)';
					|en = 'Deletion mark is set (%DocumentsCount%)'; fa = 'Deletion mark is set (%DocumentsCount%)';
					|it = 'Il contrassegno per la cancellazione è stato impostato (%DocumentsCount%)';
					|pl = 'Ustawiono zaznaczenie usunięcia (%DocumentsCount%)';
					|tr = 'Silme işareti yapılandırıldı (%DocumentsCount%)'"));
			NotificationText1 = StrReplace(NotificationText1, "%DocumentsCount%", ReferencesArrray.Count());
			ActionOnClick = "";
		Else
			Document = ReferencesArrray[0];
			NotificationText1 = ?(Not MarkToDelete,
				NStr("vi = 'Bỏ đặt dấu xóa';
					|ru = 'Пометка удаления снята';
					|en = 'Deletion mark is cleared'; fa = 'Deletion mark is cleared';
					|it = 'Il contrassegno per la cancellazione è stato rimosso';
					|pl = 'Usunięto zaznaczenie usunięcia';
					|tr = 'Silme işareti kaldırıldı'"),
				NStr("vi = 'Đã đặt dấu xóa';
					|ru = 'Пометка удаления установлена';
					|en = 'Deletion mark is set'; fa = 'Deletion mark is set';
					|it = 'Il contrassegno per la cancellazione è stato impostato';
					|pl = 'Ustawiono zaznaczenie usunięcia';
					|tr = 'Silme işareti yapılandırıldı'"));
			ActionOnClick = GetURL(Document);
		EndIf;
		
		ShowUserNotification(NotificationText1, ActionOnClick, String(Document),
			PictureLib.Information32);
			
		Items.List.Refresh();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetDeletionMarkCompletionServer(AdditionalParameters)
	
	SelectedRows = AdditionalParameters.SelectedRows;
	MarkToDelete = AdditionalParameters.SetMarkForDeletion;
	
	For Each CurRow In SelectedRows Do
		
		BeginTransaction();
		Try
			Block = New DataLock;
			
			LockItem = Block.Add("Document.WorkOutput");
			LockItem.SetValue("Ref", CurRow);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			// Recording only those objects whose tag value changes
			If MarkToDelete And Not CurRow.DeletionMark
				Or Not MarkToDelete And CurRow.DeletionMark Then
				DocumentObject = CurRow.GetObject();
				DocumentObject.SetDeletionMark(MarkToDelete)
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			DefaultLanguageCode = Common.DefaultLanguageCode();
			WriteLogEvent(
				NStr("vi = 'Lập sản lượng nhân viên';
					|ru = 'Оформление выработки сотрудников';
					|en = 'Register timesheets charge'; fa = 'ثبت کارکرد';
					|it = 'Formalizzazione della produttività dei dipendenti';
					|pl = 'Rejestracja wydajności pracowników';
					|tr = 'Zaman çizelgesi bazlı ücretlendirmenin düzenlenmesi'", DefaultLanguageCode)
					+ "." + NStr("vi = 'Đặt dấu xóa';
								|ru = 'Установка пометки на удаление';
								|en = 'Set marks for deletion'; fa = 'Set marks for deletion';
								|it = 'Impostazione contrassegnati per la cancellazione';
								|pl = 'Ustawienie zaznaczenia do usunięcia';
								|tr = 'Silme işaretinin yapılandırılması'", DefaultLanguageCode),
				EventLogLevel.Error,,
				CurRow,
				DetailErrorDescription(ErrorInfo()));
			
			ErrorPresentation = BriefErrorDescription(ErrorInfo());
			CommonClientServer.MessageToUser(ErrorPresentation, CurRow);
		EndTry;
	EndDo;
	
	Items.List.Refresh();
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		ClosingInProgress = True;
		Close();
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function DocumentsNotProcessed()
	
	CreatedDocuments = ReadDataFromSecureStorage();
	
	If Not ValueIsFilled(CreatedDocuments) Then
		Return False;
	EndIf;
	
	For Each CurDocument In CreatedDocuments Do
		
		If Not CurDocument.Posted And Not CurDocument.DeletionMark Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

&AtClient
Procedure UpdateListData() Export
	
	Items.List.Refresh();
	
EndProcedure

ClosingInProgress = False;

#EndRegion
