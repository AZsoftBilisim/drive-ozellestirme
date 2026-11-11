
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Filters = Parameters.Filter; // Structure
	BusinessOperation = Filters.BusinessOperation;
	Filters.Delete("BusinessOperation");
	
	TitleTemplate1 = NStr("vi = 'Lựa chọn dạng LCTT cho giao dịch ""%1""';
							|ru = 'Выбор статьи ДДС для операции ""%1""';
							|en = 'Select cash flow item for transaction ""%1""'; fa = 'Select cash flow item for transaction ""%1""';
							|it = 'Scelta degli articoli del Flusso Di Cassa per l''operazione ""%1""';
							|pl = 'Wybór pozycji ruchu środków pieniężnych dla operacji ""%1""';
							|tr = '""%1"" işlemi için nakit akışı kalemi seçimi'");
	Title = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, BusinessOperation);
	
	CommonClientServer.SetDynamicListFilterItem(
			ListByBusinessOperation,
			"BusinessTransactions.BusinessOperation",
			BusinessOperation,
			DataCompositionComparisonType.Equal,
			,
			True);
			
	ChoiceMode = "By_BusinessTransactions";
	Items.ListByBusinessOperationChoose.DefaultButton = True;
	
	If Not AccessRight("Edit", Metadata.Catalogs.CashFlowReportItems) Then
		Items.ChoiceMode.Visible = False;
		Items.ListByBusinessOperationHideFromSelection.Visible = False;
	EndIf;
	
	Items.ListByBusinessOperation.CurrentRow = Parameters["CurrentRow"];
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	// StandardSubsystems.Core
	NationalLanguageSupportServer.ChangeListQueryTextForCurrentLanguage(ThisObject, "ListAll");
	NationalLanguageSupportServer.ChangeListQueryTextForCurrentLanguage(ThisObject, "ListByBusinessOperation");
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TheFilterWhenYouChange(Item)
	
	UsingSelection = ?(ChoiceMode = "By_BusinessTransactions", True, False);
	
	Items.ListPageGroup.CurrentPage = ?(UsingSelection,
		Items.PageFilterByBusinessTransaction, Items.PageAll);
		
	Items.ListByBusinessOperationChoose.DefaultButton = UsingSelection;
	Items.ListAllChoose.DefaultButton = Not UsingSelection;
	
EndProcedure

&AtClient
Procedure ListByBusinessOperationValueChoice(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	NotifyChoice(ValueSelected);
	
EndProcedure

&AtClient
Procedure ListAllValueChoice(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	LinkBusinessTransactionToArticles(ValueSelected, BusinessOperation);
	If ValueSelected.Count() > 1 Then
		ChoiceMode = "By_BusinessTransactions";
		Items.ListPageGroup.CurrentPage = Items.PageFilterByBusinessTransaction;
	Else
		NotifyChoice(ValueSelected[0]);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure HideFromSelection(Command)
	
	ArrayOfArticles = Items.ListByBusinessOperation.SelectedRows;
	ArrayOfBlockedUsers = TransferToAllArticlesOnServer(ArrayOfArticles, BusinessOperation);
	
	If ArrayOfBlockedUsers.Count() = 1 Then
		ErrorTextTemplate = NStr("vi = 'Không thể chuyển dạng LCTT ""%1"".
									|Có thể là dạng LCTT đang được chỉnh sửa bởi người sử dụng khác.';
									|ru = 'Не удалось перенести статью ДДС ""%1"".
									|Возможно статья ДДС редактируется другим пользователем.';
									|en = 'Cannot transfer CF item ""%1"".
									|Maybe, CF item is being edited by another user.'; fa = 'Cannot transfer CF item ""%1"".
									|Maybe, CF item is being edited by another user.';
									|it = 'Non è stato possibile trasferire l''articolo del Flusso Di Cassa ""%1"".
									|È possibile che l''articolo del Flusso Di Cassa sta venendo modificato da un altro utente.';
									|pl = 'Przeniesienie pozycji ruchu środków pieniężnych ""%1"" nie powiodło się.
									|Być może pozycja ruchu środków pieniężnych jest edytowana przez innego użytkownika.';
									|tr = '""%1"" NA öğesi transfer edilemedi.
									|NA öğesi başka kullanıcı tarafından düzenleniyor olabilir.'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTextTemplate, ArrayOfBlockedUsers[0]);
		CommonClientServer.MessageToUser(ErrorText);
		
	ElsIf ArrayOfBlockedUsers.Count() > 1 Then
		ErrorText = NStr("vi = 'Không thể chuyển nhiều dạng LCTT.
								|Có thể là dạng LCTT đang được soạn bởi người sử dụng khác:';
								|ru = 'Не удалось перенести несколько статей ДДС.
								|Возможно статьи ДДС редактируются другими пользователями:';
								|en = 'Cannot transfer several CF items.
								|Maybe, CF items are being edited by another user:'; fa = 'Cannot transfer several CF items.
								|Maybe, CF items are being edited by another user:';
								|it = 'Non è stato possibile trasferire alcuni articoli del Flusso Di Cassa.
								|È possibile che gli articoli del Flusso Di Cassa stanno venendo modificato da altri utenti:';
								|pl = 'Przeniesienie kilku pozycji ruchu środków pieniężnych nie powiodło się.
								|Być może pozycja ruchu środków pieniężnych jest edytowana przez innego użytkownika.';
								|tr = 'Nakit akışı kalemi transfer edilemedi.
								|Belki nakit akışı kalemleri başka kullanıcılar tarafından düzenlenmekte:'");
		For IndexOf = 0 To ArrayOfBlockedUsers.UBound()-1 Do
			CFItem = ArrayOfBlockedUsers[IndexOf];
			ErrorText = ErrorText + Chars.LF + 
							"   - " + CFItem + ";"
		EndDo;
		ErrorText = ErrorText + Chars.LF + 
			"   - " + ArrayOfBlockedUsers[IndexOf] + ".";
		CommonClientServer.MessageToUser(ErrorText);
		
	EndIf;
	
	Items.ListByBusinessOperation.Refresh();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function TransferToAllArticlesOnServer(ArrayOfCFItems, BusinessOperation)
	
	ArrayOfBlockedUsers = New Array;
	
	For Each CFItem In ArrayOfCFItems Do		
		Try
			LockDataForEdit(CFItem);
		Except
			ArrayOfBlockedUsers.Add(CFItem);
			Continue;
		EndTry;
		ArticleObject = CFItem.GetObject();
		ArticleObject.DataExchange.Load = True;
		LineOfATabularSection = ArticleObject.BusinessTransactions.Find(BusinessOperation, "BusinessOperation");
		If LineOfATabularSection <> Undefined Then
			ArticleObject.BusinessTransactions.Delete(LineOfATabularSection);
			ArticleObject.Write();
		EndIf;
		ArticleObject.Unlock();
	EndDo;
	
	Return ArrayOfBlockedUsers;
	
EndFunction

&AtServerNoContext
Procedure LinkBusinessTransactionToArticles(ArrayOfCFItems, BusinessOperation)
	
	For Each CFItem In ArrayOfCFItems Do
		Try
			LockDataForEdit(CFItem);
		Except
			Continue;
		EndTry;
		ArticleObject = CFItem.GetObject();
		If ArticleObject.BusinessTransactions.Find(BusinessOperation, "BusinessOperation") = Undefined Then
			ArticleObject.DataExchange.Load = True;
			ArticleObject.BusinessTransactions.Add().BusinessOperation = BusinessOperation;
			ArticleObject.Write();
			ArticleObject.Unlock();
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure AListOfAllCreate(Command)
	
	FormParameters = New Structure("CloseOnOwnerClose, FillingValues");
	FormParameters.CloseOnOwnerClose = True;
	FormParameters.FillingValues =
		New Structure("BusinessOperation, Parent", BusinessOperation, Items.ListAll.CurrentParent);
	OpenForm("Catalog.CashFlowReportItems.Form.ItemForm", FormParameters, Items.ListAll);
	
EndProcedure

#EndRegion