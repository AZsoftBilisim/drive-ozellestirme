
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	CashPayment                    = Parameters.Parameter.CashPayment.Value;
	Items.CashPayment.Visible = Parameters.Parameter.CashPayment.Visible;
	
	PaymentCards                    = Parameters.Parameter.PaymentCards.Value;
	Items.PaymentCards.Visible = Parameters.Parameter.PaymentCards.Visible;
	
	LoyaltyCard = Parameters.Parameter.BonusPoints.Parameter;
	
	If ValueIsFilled(LoyaltyCard) And GetFunctionalOption("UseLoyaltyPrograms") Then
		
		LoyaltyCardParameters = BonusPointsServer.LoyaltyCardBonusProgram(LoyaltyCard);
		If ValueIsFilled(LoyaltyCardParameters.LoyaltyProgram) Then
			
			BalanceBonusPoints = BonusPointsServer.BalancesAndRegisteredRecordsOfBonusPoints(LoyaltyCardParameters.LoyaltyProgram, LoyaltyCardParameters.Partner);
			
			Balance = BalanceBonusPoints[0].Sum;
			RemainingBonusPoints = NStr("vi = 'Số dư:';
										|ru = 'Остаток:';
										|en = 'Balance:'; fa = 'Balance:';
										|it = 'Saldo:';
										|pl = 'Saldo:';
										|tr = 'Bakiye:'") + " " +  StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(Balance, NStr("vi = 'điểm, điểm, điểm';
																																					|ru = 'балл, балла, баллов';
																																					|en = 'point, point, points'; fa = 'point, point, points';
																																					|it = 'punti';
																																					|pl = 'punkt, punktu, punktów';
																																					|tr = 'puan, puan, puan'"));
			
			BonusPoints                                        = Parameters.Parameter.BonusPoints.Value And Balance > 0;
			Items.GroupPaymentWithBonusPoints.Visible      = Parameters.Parameter.BonusPoints.Visible;
			Items.GroupPaymentWithBonusPoints.Enabled    = Balance > 0;
			Items.DecorationNoAccrualIsMade.Visible = LoyaltyCardParameters.DoNotAccruePointsWhenPayingWithBonuses;
			
		Else
			BonusPoints = False;
			Items.GroupPaymentWithBonusPoints.Visible = False;
		EndIf;
		
	Else
		BonusPoints = False;
		Items.GroupPaymentWithBonusPoints.Visible = False;
		Items.DecorationNoAccrualIsMade.Visible = False;
	EndIf;
	
	GiftCertificates                    = Parameters.Parameter.GiftCertificates.Value;
	Items.GiftCertificates.Visible = Parameters.Parameter.GiftCertificates.Visible;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	Payment = New Structure;
	Payment.Insert("CashPayment",              CashPayment);
	Payment.Insert("BonusPoints",         BonusPoints);
	Payment.Insert("PaymentCards",        PaymentCards);
	Payment.Insert("GiftCertificates", GiftCertificates);
	
	Close(Payment);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

