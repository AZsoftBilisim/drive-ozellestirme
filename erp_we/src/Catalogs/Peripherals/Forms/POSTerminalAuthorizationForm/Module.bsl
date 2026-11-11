
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	ListOfMapTypes = Undefined;

	TemporaryAmount = 0;
	If Parameters.Property("Sum", TemporaryAmount)
	   And TemporaryAmount > 0 Then
		Sum = TemporaryAmount;
	Else
		Sum = 0;
	EndIf;

	TimeLimitOfSum = 0;
	If Parameters.Property("AmountLimit", TimeLimitOfSum)
	   And TimeLimitOfSum > 0 Then
		Items.Sum.MaxValue = TimeLimitOfSum;
	Else
		Items.Sum.MaxValue = Undefined;
	EndIf;
	
	If Parameters.Property("NoAmountEditingAllowed") Then
		Items.Sum.ReadOnly = Parameters.NoAmountEditingAllowed;
	EndIf;
	
	If Parameters.Property("ListOfMapTypes", ListOfMapTypes)
	   And TypeOf(ListOfMapTypes) = Type("ValueList")
	   And ListOfMapTypes. Count() > 0 Then
		For Each ListLine In ListOfMapTypes Do
			Items.CardType.ChoiceList.Add(ListLine.Value, ListLine.Presentation);
		EndDo;
		Items.CardType.Visible = True;
	EndIf;
	
	Items.CardNumber.Visible            = False;
	Items.CardNumber.ReadOnly       = True;
	Items.CardNumber.TextEdit = False;

	If Parameters.Property("ShowCardNumber", ShowCardNumber) Then
		If ShowCardNumber Then
			Items.CardNumber.Visible            = True;
			Items.CardNumber.ReadOnly       = False;
			Items.CardNumber.TextEdit = True;
		EndIf;
	EndIf;
	
	If Items.Sum.ReadOnly Then
		Items.Sum.DefaultItem = False;
		If Items.CardType.Visible And Items.CardType.ChoiceList.Count() > 1 Then
			Items.CardType.DefaultItem = True;
		ElsIf Items.CardNumber.Visible Then
			Items.CardNumber.DefaultItem = True;
		Else
			Items.ExecuteOperation.DefaultItem = True;
		EndIf;
	EndIf;
	
	If Parameters.Property("SpecifyAdditionalData") Then
		SpecifyAdditionalData = True;
	EndIf;
	
	If Parameters.Property("ReferenceNumber") Then
		ReferenceNumber = Parameters.ReferenceNumber;
	EndIf;
	
	If Parameters.Property("ReceiptNumber") Then
		ReceiptNumber = Parameters.ReceiptNumber;
	EndIf;
	
	Items.ManualDataEntryGroup.Visible = SpecifyAdditionalData;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SpecifyAdditionalDataOnChange(Item)

	Items.ManualDataEntryGroup.Visible = SpecifyAdditionalData;

EndProcedure

&AtClient
Procedure ExecuteOperation(Command)
	
	Errors = "";
	
	ClearMessages();
	
	If Sum = 0 Then
		Errors = NStr("vi = 'Không thể thực hiện thanh toán với số tiền bằng 0.';
						|ru = 'Платеж не может быть осуществлен на нулевую сумму.';
						|en = 'Payment can not be performed for the amount equal to zero.'; fa = 'Payment can not be performed for the amount equal to zero.';
						|it = 'Il pagamento non può essere effettuato per un importo nullo.';
						|pl = 'Nie można dokonać płatności, której wartość wynosi zero.';
						|tr = 'Ödeme tutarı sıfır olamaz.'");
	EndIf;
	
	If ShowCardNumber And Not ValueIsFilled(CardNumber) Then
		Errors = Errors + ?(IsBlankString(Errors),"",Chars.LF) + NStr("vi = 'Không thể thực hiện thanh toán mà không có số thẻ.';
																		|ru = 'Платеж не может быть осуществлен без номера карты.';
																		|en = 'Payment can not be performed without number of card.'; fa = 'Payment can not be performed without number of card.';
																		|it = 'Il pagamento non può essere effettuato senza il numero della carta.';
																		|pl = 'Nie można dokonać płatności bez numeru karty.';
																		|tr = 'Ödeme, kart numarası olmadan yapılamaz.'");
	EndIf;
	
	If IsBlankString(Errors) Then
		If Not SpecifyAdditionalData Then
			ReferenceNumber = "";
			ReceiptNumber      = "";   
			POSTerminalReceiptNumber    = "";
		EndIf;
		
		ReturnStructure = New Structure();
		ReturnStructure.Insert("Sum"         , Sum);
		ReturnStructure.Insert("CardData"   , "");
		ReturnStructure.Insert("ReferenceNumber", ReferenceNumber);
		ReturnStructure.Insert("CardType"      , CardType);
		ReturnStructure.Insert("CardNumber"    , CardNumber);
		ReturnStructure.Insert("ReceiptNumber"     , ReceiptNumber);
		ReturnStructure.Insert("POSTerminalReceiptNumber"   , POSTerminalReceiptNumber);
		
		Close(ReturnStructure);
		
	Else
		CommonCELClient.MessageToUser(Errors,,"CardNumber");
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SumTextEditEnd(Item, Text, ChoiceData, StandardProcessing)

	If Items.Sum.MaxValue <> Undefined
	   And Items.Sum.MaxValue < Number(Text) Then
	   
		StandardProcessing = False;
		ValueStructure = New Structure;
		ValueStructure.Insert("Warning", NStr("vi = 'Số tiền thanh toán bằng thẻ vượt quá số tiền chuyển khoản cần thiết.
		|Giá trị sẽ thay đổi đến mức tối đa có thể.';
		|ru = 'Сумма оплаты по карте превышает необходимую безналичную оплату.
		|Значение будет изменено на максимально возможное.';
		|en = 'The amount paid by card exceeds required payment. 
		|The amount will be changed to the maximum allowed.'; fa = 'The amount paid by card exceeds required payment. 
		|The amount will be changed to the maximum allowed.';
		|it = 'L''importo del pagamento sulla carta supera il pagamento cashless richiesto.
		|l valore verrà impostato al massimo possibile.';
		|pl = 'Wartość płatności kartą przekracza niezbędną płatność bezgotówkową.
		|Wartość zostanie zmieniona na maksymalną możkiwą.';
		|tr = 'Karttaki ödeme tutarı, gereken gayri nakdi ödeme tutarını aşıyor.
		|Değer mümkün olan maksimum değere değiştirilecektir.'"));
		ValueStructure.Insert("Value", Format(Items.Sum.MaxValue, "NFD=2; NZ=0; NG=0; NN=1"));
		
		ValueList = New ValueList;
		ValueList.Add(ValueStructure);
		ChoiceData = ValueList;
		
	EndIf;

EndProcedure

#EndRegion
