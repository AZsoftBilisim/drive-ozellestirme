
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	LoadList(Cancel);
	
	InitializeListOfDocuments();
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = FormAttributeToValue("ListCreatedDocuments").Columns["Ref"].ValueType;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	SetFormHeader();
	
	CustomizeFormElements();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not CloseWithoutConfirmation Then
		
		StandardProcessing = False;
		Cancel = True;
		
		If Exit Then
			WarningText = NStr("vi = 'Dữ liệu đã thay đổi. Tất cả thay đổi sẽ bị mất.';
								|ru = 'Данные были изменены. Все изменения будут потеряны.';
								|en = 'All changes made to the data will be lost.'; fa = 'All changes made to the data will be lost.';
								|it = 'I dati sono stati modificati. Tutte le modifiche verranno perse.';
								|pl = 'Dane zostały zmienione. Wszystkie zmiany zostaną utracone.';
								|tr = 'Veri değişti. Tüm değişiklikler kaybolacak.'");
			Return;
		EndIf;
		
		Buttons = New ValueList();
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Chấp nhận và đóng';
												|ru = 'Принять и закрыть';
												|en = 'Accept and close'; fa = 'پذیرش و بستن';
												|it = 'Accettare e chiudere';
												|pl = 'Przyjąć i zamknąć';
												|tr = 'Kabul et ve kapat'"));
		Buttons.Add(DialogReturnCode.No, NStr("vi = 'Hủy bỏ và xóa';
												|ru = 'Отменить и удалить';
												|en = 'Cancel and delete'; fa = 'انصراف و حذف';
												|it = 'Annullare e cancellare';
												|pl = 'Anulować i usunąć';
												|tr = 'İptal et ve sil'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		QueryText = NStr("vi = 'Chọn giao dịch được thực hiện với các chứng từ đã tạo';
						|ru = 'Выберите действие, которое необходимо произвести с созданными документами';
						|en = 'Select an action to be done with the created documents'; fa = 'Select an action to be done with the created documents';
						|it = 'Selezionare l''azione da eseguire per i documenti creati';
						|pl = 'Wybierz działanie, które należy wykonać z utworzonymi dokumentami';
						|tr = 'Oluşturduğunuz belgeler üzerinde gerçekleştirilecek eylemi seçin'");
		
		ShowQueryBox(New CallbackDescription("QuestionOfClosure", ThisObject), QueryText, Buttons);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_VendorInvoice"
		Or EventName = "Write_GoodsReceiptForStorage" Then
		
		InitializeListOfDocuments();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListCreatedDocuments

&AtClient
Procedure ListCreatedDocumentsOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
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
	
	DeleteCreatedDocuments();
	
	Notify("Write_VendorInvoice"); // Need to update the list for registration
	
	CloseWithoutConfirmation = True;
	Close();
	
EndProcedure

&AtServer
Procedure DeleteCreatedDocuments()
	
	ArrayOfDeleteLinks	= ListCreatedDocuments.Unload(, "Ref").UnloadColumn("Ref");
	ErrorList 			= TMCommonUse.SetMarkForDeletingDocuments(ArrayOfDeleteLinks);
	
	CommonClientServer.ReportErrorsToUser(ErrorList);
	ListCreatedDocuments.Clear();
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	If ListCreatedDocuments.Count() > 0 Then
		
		Buttons = New ValueList();
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Xóa bỏ';
												|ru = 'Удалить';
												|en = 'Delete'; fa = 'حذف';
												|it = 'Eliminare';
												|pl = 'Delete';
												|tr = 'Sil'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		QueryText = NStr("vi = 'Xóa chứng từ đã tạo?';
						|ru = 'Удалить сформированные документы?';
						|en = 'Delete generated documents?'; fa = 'Delete generated documents?';
						|it = 'Eliminare documenti generati?';
						|pl = 'Czy usunąć wygenerowane dokumenty?';
						|tr = 'Oluşturulan belgeler silinsin mi?'");
		
		ShowQueryBox(New CallbackDescription("BackCompletion", ThisObject), QueryText, Buttons);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Accept(Command)
	CloseWithoutConfirmation = True;
	Close();
EndProcedure

&AtClient
Procedure ListCreatedDocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ShowValue(Undefined, Item.CurrentData.Ref);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure LoadList(Cancel)
	
	//Data objectmetall = New Array;
	CreatedDocuments = ReadDataFromSecureStorage();
	
	If ValueIsFilled(CreatedDocuments) Then
		DeleteDataFromSecureStorage();
	Else
		Cancel = True;
		
		Raise NStr("vi = 'Một ngoại lệ xảy ra trong khi tạo chứng từ.';
					|ru = 'Произошла исключительная ситуация при создании документов.';
					|en = 'An exception is thrown when generating documents.'; fa = 'An exception is thrown when generating documents.';
					|it = 'Si è verificata una situazione eccezionale durante la creazione di documenti.';
					|pl = 'Wystąpiła sytuacja wyjątkowa podczas tworzenia dokumentów.';
					|tr = 'Belgelerin oluşturulması sırasında istisnai bir durum meydana geldi.'");
	EndIf;
	
	For Each CurRow In CreatedDocuments Do
		DocumentsList.Add(CurRow);
	EndDo;
	
EndProcedure

&AtServerNoContext
Function ReadDataFromSecureStorage()
	
	SetPrivilegedMode(True);
	ProtectedData = Common.ReadDataFromSecureStorage(Users.AuthorizedUser(),
																			"FormCreatedPurchaseDocuments");
	SetPrivilegedMode(False);
	
	Return ProtectedData
	
EndFunction

&AtServerNoContext
Procedure DeleteDataFromSecureStorage()
	
	SetPrivilegedMode(True);
	Common.DeleteDataFromSecureStorage(Users.AuthorizedUser(),
														"FormCreatedPurchaseDocuments");
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Procedure InitializeListOfDocuments()
	
	Query = New Query();
	Query.Parameters.Insert("Documents", DocumentsList.UnloadValues());
	Query.Text = 
	"SELECT ALLOWED
	|	DocumentsData.Ref,
	|	CAST(DocumentsData.StorageLocation.Key AS Catalog.Warehouses) AS Warehouse,
	|	DocumentsData.Organization,
	|	DocumentsData.BusinessOperation,
	|	CASE
	|		WHEN DocumentsData.Posted
	|			THEN 0
	|		ELSE CASE
	|				WHEN DocumentsData.DeletionMark
	|					THEN 1
	|				ELSE 2
	|			END
	|	END AS Picture,
	|	DocumentsData.Partner,
	|	DocumentsData.Counterparty.Key AS Counterparty,
	|	DocumentsData.LineOfBusiness
	|
	|INTO TTDocumentData
	|
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsData
	|WHERE
	|	DocumentsData.Ref IN(&Documents)
	|	AND NOT DocumentsData.AdditionalRecord
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDocumentData.Ref,
	|	TTDocumentData.Warehouse,
	|	TTDocumentData.Organization,
	|	TTDocumentData.BusinessOperation,
	|	TTDocumentData.Picture,
	|	TTDocumentData.Partner,
	|	TTDocumentData.Counterparty,
	|	TTDocumentData.LineOfBusiness
	|FROM
	|	TTDocumentData AS TTDocumentData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(TTDocumentData.Ref),
	|	MAX(TTDocumentData.Warehouse),
	|	MAX(TTDocumentData.Organization),
	|	MAX(TTDocumentData.BusinessOperation),
	|	MAX(TTDocumentData.Picture),
	|	MAX(TTDocumentData.Partner),
	|	MAX(TTDocumentData.Counterparty),
	|	MAX(TTDocumentData.LineOfBusiness)
	|FROM
	|	TTDocumentData AS TTDocumentData";
	
	Result = Query.ExecuteBatch();
	ColumnSelection = Result[2].Select();
	ColumnSelection.Next();
	For Each FieldElement In Items.ListCreatedDocuments.ChildItems Do
		PathParts = StrSplit(FieldElement.DataPath,".");
		If ValueIsFilled(PathParts[0])
			And ThisForm[PathParts[0]] = ListCreatedDocuments Then
			FieldElement.Visible = ValueIsFilled(ColumnSelection[PathParts[1]]);
		EndIf;
	EndDo;
	ListCreatedDocuments.Load(Result[1].Unload());
	
EndProcedure

&AtServer
Procedure SetFormHeader() 
	
	DocumentsCount = ListCreatedDocuments.Count();
	
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

&AtClient
Procedure QuestionOfClosure(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.Cancel Then
		Return;
	ElsIf Response = DialogReturnCode.No Then
		BackCompletion(Response, Undefined);
	Else
		CloseWithoutConfirmation = True;
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()

	SenderWarehouse_ = False;
	SenderDivision = False;
	
	For Each RowData In ListCreatedDocuments Do
		
		If ValueIsFilled(RowData.Warehouse) And TypeOf(RowData.Warehouse) = Type("CatalogRef.Warehouses") Then
			SenderWarehouse_ = True;
		EndIf;
		If ValueIsFilled(RowData.Warehouse) And TypeOf(RowData.Warehouse) = Type("CatalogRef.BusinessStructure") Then
			SenderDivision = True;
		EndIf;
		
		If SenderWarehouse_ And SenderDivision Then
			Break;
		EndIf;
		
	EndDo;
	
	If SenderWarehouse_ And SenderDivision Then
		Items.ListCreatedDocumentsWarehouse.Title = NStr("vi = 'Người gửi';
														|ru = 'Отправитель';
														|en = 'Sender'; fa = 'فرستنده';
														|it = 'Mittente';
														|pl = 'Nadawca';
														|tr = 'Gönderen'");
	ElsIf SenderDivision Then
		Items.ListCreatedDocumentsWarehouse.Title = NStr("vi = 'Bộ phận';
														|ru = 'Подразделение';
														|en = 'Business unit'; fa = 'Business unit';
														|it = 'Reparto';
														|pl = 'Dział';
														|tr = 'Departman'");
	EndIf; 
	
EndProcedure

#EndRegion