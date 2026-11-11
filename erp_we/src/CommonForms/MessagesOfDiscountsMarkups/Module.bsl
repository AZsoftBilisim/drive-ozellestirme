
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	LoyaltyCard = Parameters.LoyaltyCard;
	ReplacedLoyaltyCardKind = Common.ObjectAttributeValue(Parameters.LoyaltyCard, "Owner");
	SelectedPaymentMethod = Parameters.SelectedPaymentMethod;
	
	Partner    = Parameters.Partner;
	Counterparty = Parameters.Counterparty;
	Terms = Parameters.Terms;
	
	Items.Close.Visible        = Not Parameters.BeforeMakingThePaymentInTheKKMReceipt;
	Items.Cancel.Visible         =    Parameters.BeforeMakingThePaymentInTheKKMReceipt;
	Items.GoToPayment.Visible =    Parameters.BeforeMakingThePaymentInTheKKMReceipt;
	
	ArrayOfDiscountMargins = New Array;
	For Each TSRow In Parameters.Messages Do
		ArrayOfDiscountMargins.Add(TSRow.DiscountMarkup);
		NewMessage = MessageTable.Add();
		NewMessage.DiscountMarkup  = TSRow.DiscountMarkup;
		NewMessage.RemindLater = TSRow.RemindLater;
	EndDo;
	
	DetailsOfDiscountsSurcharges = Common.ObjectsAttributesValues(ArrayOfDiscountMargins, "MessageText, LoyaltyCardKind"); 
	
	For Each TSRow In MessageTable Do
		TSRow.MessageText = DetailsOfDiscountsSurcharges.Get(TSRow.DiscountMarkup).MessageText;
		TSRow.CardKind       = DetailsOfDiscountsSurcharges.Get(TSRow.DiscountMarkup).LoyaltyCardKind;
	EndDo;
	
	MessageNo = 1;
	TotalMessages = MessageTable.Count();
	
	MessageTable.Sort("RemindLater Desc,DiscountMarkup Desc");
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	DisplayCurMessage();
	
EndProcedure

&AtClient
Procedure OnClose()
	
	If FormOwner <> Undefined Then
		
		MessageTable[MessageNo - 1].RemindLater = RemindLater;
		
		ArrayOfMessages = New Array;
		For Each TSRow In MessageTable Do
			ArrayOfMessages.Add(New Structure("DiscountMarkup, RemindLater", TSRow.DiscountMarkup, TSRow.RemindLater));
		EndDo;
		
		Notify("MessagesReceived", New Structure("Messages, OwnerForm", ArrayOfMessages, FormOwner.UUID), Undefined);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RemindLaterOnChange(Item)
	
	MessageTable[MessageNo - 1].ChangedByUser = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure NextMessage(Command)
	
	MessageTable[MessageNo - 1].RemindLater = RemindLater;
	
	MessageNo = MessageNo + 1;
	
	DisplayCurMessage();

EndProcedure

&AtClient
Procedure PreviousMessage(Command)
	
	MessageTable[MessageNo - 1].RemindLater = RemindLater;
	
	MessageNo = MessageNo - 1;
	
	DisplayCurMessage();
	
EndProcedure

&AtClient
Procedure IssueCard(Command)
	
	TSRow = MessageTable[MessageNo - 1];
	
	OpeningParameters = New Structure("Mode, RequiredNewCardKind, ReplacedCard, Partner, Counterparty, Terms");
	OpeningParameters.RequiredNewCardKind = TSRow.CardKind;
	If Not ValueIsFilled(LoyaltyCard) Then
		OpeningParameters.Mode = "RegisterNewLoyaltyCard";
	Else
		OpeningParameters.Mode = "ReplaceLoyaltyCard";
		OpeningParameters.ReplacedCard = LoyaltyCard;
	EndIf;
	OpeningParameters.Partner    = Partner;
	OpeningParameters.Counterparty = Counterparty;
	OpeningParameters.Terms = Terms;
	
	ValueSelected = OpenForm("Catalog.LoyaltyCards.Form.RegistrationWizard", OpeningParameters, FormOwner);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(False);
	
EndProcedure

&AtClient
Procedure GoToPayment(Command)
	
	If SelectedPaymentMethod <> Undefined Then
		Close(SelectedPaymentMethod);
	Else
		Close(True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure DisplayCurMessage()
	
	TSRow = MessageTable[MessageNo - 1];
	If ValueIsFilled(TSRow.CardKind) Then
		If ValueIsFilled(LoyaltyCard) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thay thế thẻ khách hàng thân thiết ""%1"" sang thẻ ""%2""';
																						|ru = 'Заменить карту лояльности ""%1"" на карту ""%2""';
																						|en = 'Replace loyalty card ""%1"" with card ""%2""'; fa = 'Replace loyalty card ""%1"" with card ""%2""';
																						|it = 'Sostituire carta fedeltà ""%1"" con la carta ""%2""';
																						|pl = 'Zamień kartę lojalnościową ""%1"" na kartę ""%2""';
																						|tr = '""%1"" sadakat kartını ""%2"" kartına değiştir'"), ReplacedLoyaltyCardKind, TSRow.CardKind);
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Cấp thẻ khách hàng thân thiết ""%1""';
																						|ru = 'Выдать карту лояльности ""%1""';
																						|en = 'Issue loyalty card ""%1""'; fa = 'Issue loyalty card ""%1""';
																						|it = 'Emettere carta fedeltà ""%1""';
																						|pl = 'Wydaj kartę lojalnościową ""%1""';
																						|tr = '""%1"" sadakat kartını ver'"), TSRow.CardKind);
		EndIf;
	Else
		MessageText = TSRow.MessageText;
	EndIf;
	If Not TSRow.ChangedByUser Then
		TSRow.RemindLater = False;
	EndIf;
	RemindLater = TSRow.RemindLater;
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thông báo %1 trong %2';
																			|ru = 'Сообщение %1 из %2';
																			|en = 'Message %1 of %2'; fa = 'Message %1 of %2';
																			|it = 'Messaggio %1 di %2';
																			|pl = 'Wiadomość %1 z %2';
																			|tr = '%2''dan %1 mesajı'"), MessageNo, TotalMessages);
	
	Items.RegisterLoyaltyCard.Visible =
		ValueIsFilled(TSRow.CardKind) And AccessRight("Update", Metadata.Catalogs.LoyaltyCards);
	Items.PreviousMessage.Visible = MessageNo > 1;
	Items.NextMessage.Visible  = Not MessageNo = MessageTable.Count();
	
EndProcedure

#EndRegion
