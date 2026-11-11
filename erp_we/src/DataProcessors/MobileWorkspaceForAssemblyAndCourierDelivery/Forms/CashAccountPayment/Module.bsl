
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("ReferenceOrder", ReferenceOrder);
	Parameters.Property("AmountToPay", AmountToPay);
	Parameters.Property("Currency", Currency);
	Parameters.Property("Warehouse", Warehouse);
	
	UpdateFormData();
	SetConditionalAppearance();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReceivedSumOnChange(Item)
	
	RecalculateChange();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExecuteAProcessCommand(Command)
	
	Cancel = False;
	
	If ReceivedSum >= AmountToPay Then
		
		AcceptPaymentAndIssueReceipt(Cancel);
		
		If Not Cancel Then
			Close(True);
		EndIf;
	Else
		If ReceivedSum = 0 Then
			ErrorText = NStr("vi = 'Chưa chỉ ra số tiền đã nhận.';
							|ru = 'Не указана полученная сумма.';
							|en = 'The amount received is not specified.'; fa = 'The amount received is not specified.';
							|it = 'Importo ricevuto non indicato.';
							|pl = 'Nie podano otrzymanej wartości.';
							|tr = 'Alınan tutar belirtilmedi.'");
		Else
			ErrorText = NStr("vi = 'Số tiền đã nhận nhỏ hơn số tiền cần thanh toán.';
							|ru = 'Полученная сумма меньше суммы к оплате.';
							|en = 'The amount received is less than the amount due.'; fa = 'The amount received is less than the amount due.';
							|it = 'L''importo ricevuto è inferiore all''importo da pagare.';
							|pl = 'Otrzymana wartość jest mniejszy niż wartość do zapłaty.';
							|tr = 'Alınan tutar, ödenecek borçtan daha az.'");
		EndIf;
		CommonClient.MessageToUser(ErrorText);
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure AddTheReceivedAmount(Command)
	
	If Command.Name = "AddWithoutChange" Then
		ReceivedSum = AmountToPay;
	ElsIf Command.Name = "Add5000" Then
		ReceivedSum = ReceivedSum + 5000;
	ElsIf Command.Name = "Add1000" Then
		ReceivedSum = ReceivedSum + 1000;
	ElsIf Command.Name = "Add500" Then
		ReceivedSum = ReceivedSum + 500;
	ElsIf Command.Name = "Add200" Then
		ReceivedSum = ReceivedSum + 200;
	ElsIf Command.Name = "Add100" Then
		ReceivedSum = ReceivedSum + 100;
	EndIf;
	
	RecalculateChange();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateFormData()
	
	Module = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery;
	AmountToPayPresentation = Module.AmountToPayPresentation(ThisObject);
	CurrencyPresentation = Module.CurrencyPresentation(Currency);
	
	Items.DecorationAmountToBePaid.Title = New FormattedString(AmountToPayPresentation,
		StyleFonts.EnlargedTextFontSelectedAssemblyAndDelivery,
		StyleColors.TextColorMainKittingAndDelivery);
		
	Items.DecorationEnteringTheAmountCurrency.Title = New FormattedString(CurrencyPresentation,
		StyleFonts.EnlargedTextFontSelectedAssemblyAndDelivery,
		StyleColors.TextColorMainKittingAndDelivery);
		
	RecalculateChange();
	OverrideCurProcessCommand();
		
EndProcedure

&AtServer
Procedure RecalculateChange()
	
	Change_2 = ReceivedSum - AmountToPay;
	Module = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery;
	Change_2Presentation = Module.Change_2Presentation(ThisObject);
	
	Items.DecorationDelivery.Title = New FormattedString(Change_2Presentation,
		StyleFonts.TextFontAssemblyAndDelivery,
		StyleColors.TextColorMainKittingAndDelivery);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReceivedSum.Name);
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReceivedSum");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = AmountToPay;
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.NegativeValuesTextColor);
	
EndProcedure

#Region ProcessActions

&AtServer
Procedure OverrideCurProcessCommand()
	
	DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.OverrideCurProcessCommand(ThisObject);
	
EndProcedure

&AtServer
Procedure AcceptPaymentAndIssueReceipt(Cancel = False) 
	
	Module = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery;
	Module.CreateCourierCashRegister(ReferenceOrder, AmountToPay, Cancel);
	
	If StrFind(CurrentAction1, "IssueReceipt")
		And Not Cancel Then
		Module.IssueReceipt(ReferenceOrder, Cancel);
	EndIf;
	
	If Not Cancel Then
		Module.CompleteDelivery(ReferenceOrder);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
