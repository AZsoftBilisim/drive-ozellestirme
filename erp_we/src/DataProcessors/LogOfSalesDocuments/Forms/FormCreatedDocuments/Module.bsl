
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	LoadList(Cancel);
	
	TypesArray = New Array;;
	FullNamesArray = New Array;
	For Each ListLine In DocumentsList Do
		
		If ValueIsFilled(ListLine.Value) Then
			ValueType = TypeOf(ListLine.Value);
			FullName = Metadata.FindByType(ValueType).FullName();
			If Not FullName = Undefined And FullNamesArray.Find(FullName) = Undefined Then
				FullNamesArray.Add(FullName);
			EndIf;
			
			If TypesArray.Find(ValueType) = Undefined Then
				TypesArray.Add(ValueType);
			EndIf;
		EndIf;
		
	EndDo;
	
	IDsMap = Common.MetadataObjectIDs(FullNamesArray);
	If ValueIsFilled(IDsMap) Then
		
		ArrayOfIdentifiers = New Array;
		For Each MapRow In IDsMap Do
			ArrayOfIdentifiers.Add(MapRow.Value);
		EndDo;
		CommonClientServer.SetDynamicListParameter(ListCreatedDocuments, "ArrayOfIdentifiers", ArrayOfIdentifiers);
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	If ValueIsFilled(TypesArray) Then
		TypesList = New TypeDescription(TypesArray);
	Else
		TypesList = ListCreatedDocuments.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	EndIf;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.ListCreatedDocumentsCommandBar;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	SetFormHeader();
	
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
	
	If EventName = "Write_CustomerInvoiceServices"
		Or EventName = "Write_TransferOfGoodsToBailee"
		Or EventName = "Write_CustomerInvoice"
		Or EventName = "Write_CashAccountReceiptNote"
		Or EventName = "Write_ReceiptOfGoodsFromCustodian"
		Or EventName = "Write_GoodsShipmentFromStorage" Then
		
		Items.ListCreatedDocuments.Refresh();
		
	EndIf;
	
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
	
	ErrorList = DeleteCreatedDocuments();
	If ValueIsFilled(ErrorList) Then
		CommonClientServer.ReportErrorsToUser(ErrorList);
	Else
		CloseWithoutConfirmation = True;
		Close();
	EndIf;
	Notify("CancellationOfSalesDocuments",, ThisObject);
	
EndProcedure

&AtServer
Function DeleteCreatedDocuments()
	
	RemovalLinks = DocumentsList.UnloadValues();
	TMCommonUse.SetMarkForDeletingDocuments(RemovalLinks);
	
	Items.ListCreatedDocuments.Refresh();
	
	Return Undefined;
	
EndFunction

&AtClient
Procedure Back(Command)
	Buttons = New ValueList();
	Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Xóa chứng từ';
											|ru = 'Удалить документы';
											|en = 'Delete documents'; fa = 'حذف اسناد';
											|it = 'Cancellare i documenti';
											|pl = 'Usuń dokumenty';
											|tr = 'Belgeleri sil'"));
	Buttons.Add(DialogReturnCode.Cancel);
	
	QueryText = NStr("vi = 'Các chứng từ được tạo sẽ bị xóa.';
					|ru = 'Сформированные документы будут удалены.';
					|en = 'Generated documents will be deleted.'; fa = 'اسناد ایجادشده حذف خواهند شد.';
					|it = 'I documenti generati saranno cancellati.';
					|pl = 'Utworzyć dokumenty będą usunięte.';
					|tr = 'Oluşturulan belgeler silinecek.'");
	
	ShowQueryBox(New CallbackDescription("BackCompletion", ThisObject), QueryText, Buttons);
EndProcedure

&AtClient
Procedure Accept(Command)
	QuestionUnverifiedDocuments();
EndProcedure

&AtClient
Procedure Post(Command)
	TMCommonUseClient.PostDocuments(Items.ListCreatedDocuments, Title);
	ProvisionInDocumentsClient.CheckToRunBackgroundInventoryAllocationJob();
EndProcedure

&AtClient
Procedure UndoPosting(Command)
	TMCommonUseClient.UndoPosting(Items.ListCreatedDocuments, Title);
	ProvisionInDocumentsClient.CheckToRunBackgroundInventoryAllocationJob();
EndProcedure

&AtClient
Procedure ListCreatedDocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListCreatedDocumentsOnActivateRow(Item)
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure LoadList(Cancel)
	
	ParametersOfCreatedDocuments = SalesServer.ReadDataFromSecureStorage("FormCreatedSalesDocuments");
	If TypeOf(ParametersOfCreatedDocuments) = Type("Structure") Then
		CreatedDocuments = ParametersOfCreatedDocuments.Parameters.CreatedDocuments;
	Else
		CreatedDocuments = ParametersOfCreatedDocuments;
	EndIf;
	If ValueIsFilled(CreatedDocuments) Then
		SalesServer.DeleteDataFromSecureStorage("FormCreatedSalesDocuments");
	Else
		Raise NStr("vi = 'Một ngoại lệ xảy ra trong khi tạo chứng từ.';
					|ru = 'Произошла исключительная ситуация при создании документов.';
					|en = 'An exception is thrown when generating documents.'; fa = 'An exception is thrown when generating documents.';
					|it = 'Si è verificata una situazione eccezionale durante la creazione di documenti.';
					|pl = 'Wystąpiła sytuacja wyjątkowa podczas tworzenia dokumentów.';
					|tr = 'Belgelerin oluşturulması sırasında istisnai bir durum meydana geldi.'");
		Cancel = True;
	EndIf;
	
	For Each CurRow In CreatedDocuments Do
		DocumentsList.Add(CurRow.Document);
	EndDo;
	
	CommonClientServer.SetDynamicListFilterItem(
		ListCreatedDocuments,
		"Ref",
		DocumentsList.UnloadValues(),
		DataCompositionComparisonType.InList,
		,
		True);
	
EndProcedure

&AtServer
Procedure SetFormHeader() 
	
	Title = StringFunctionsClientServer.StringWithNumberForAnyLanguage(
		NStr("vi = ';Đã tạo %1 chứng từ;;Đã tạo %1 chứng từ;Đã tạo%1 chứng từ;Đã tạo%1 chứng từ';
			|ru = ';Создан %1 документ;;Создано %1 документа;Создано %1 документов;Создано %1 документа';
			|en = ';Created %1 document;;;;Created %1 documents$$$remove it%1%1$$$'; fa = ';Created %1 document;;;;Created %1 documents$$$remove it%1%1$$$';
			|it = ';Создан %1 документ;;Создано %1 документа;Создано %1 документов;Создано %1 документа';
			|pl = ';Created %1 document;;;;Created %1 documents$$$remove it%1%1$$$';
			|tr = '; Belge %1 oluşturuldu;; %1Belgesi oluşturuldu; %1Belgeleri oluşturuldu; %1Belgesi oluşturuldu'"), 
		DocumentsList.Count(),, "NZ=0");
	
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
Procedure QuestionUnverifiedDocuments()
	If HasUnpostedDocuments() Then
		Buttons = New ValueList();
		Buttons.Add(DialogReturnCode.Yes);
		Buttons.Add(DialogReturnCode.No);
		
		QueryText = NStr("vi = 'Một số chứng từ đã không được doanh nghiệp. Bạn có chắc chắn muốn để lại các chứng từ không được gửi?';
						|ru = 'Некоторые документы не были проведены. Вы уверены, что хотите оставить документы непроведенными?';
						|en = 'Some documents were not posted. Are you sure you want to leave the documents unposted?'; fa = 'Some documents were not posted. Are you sure you want to leave the documents unposted?';
						|it = 'Alcuni documenti non sono stati registrati. Siete sicuri di voler lasciare i documenti non registrati?';
						|pl = 'Niektóre dokumenty nie zostały zaksięgowane. Czy na pewno chcesz zostawić dokumenty bez zaksięgowania?';
						|tr = 'Bazı belgeler yerine getirilmemiştir. Belgeleri uygulanmadan bırakmak istediğinizden emin misiniz?'");
		ShowQueryBox(New CallbackDescription("QuestionAboutClosingUnverifiedDocuments", ThisObject), QueryText, Buttons);
	Else
		CloseWithoutConfirmation = True;
		Notify("Accept_FormOfCreatedDocuments",, ThisForm);
		Close();
	EndIf;
EndProcedure

&AtClient
Procedure QuestionAboutClosingUnverifiedDocuments(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.No Then
		Return;
	ElsIf Response = DialogReturnCode.Yes Then
		CloseWithoutConfirmation = True;
		Notify("Accept_FormOfCreatedDocuments",, ThisForm);
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
Procedure SetConditionalAppearance()

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListCreatedDocuments.Date", "ListCreatedDocumentsDate");
	
EndProcedure

#EndRegion