#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Stages.Total("PaymentPercentage") <> 100 Then
		
		ErrorText = NStr("vi = 'Tỷ lệ phần trăm thanh toán theo tất cả giai đoạn phải bằng 100%';
						|ru = 'Процент платежей по всем этапам должен быть равен 100%';
						|en = 'Payment percentage at all stages should be equal to 100 %'; fa = 'Payment percentage at all stages should be equal to 100 %';
						|it = 'La percentuale di pagamento per tutte le fasi deve essere pari al 100%';
						|pl = 'Procent płatności dla wszystkich etapów powinien wynosić 100%';
						|tr = 'Tüm aşamalar için ödeme yüzdesi 100% olmalıdır'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"Stages",
			,
			Cancel);
		
	EndIf;
	
	If Stages.Total("PackageDepositPercentage") <> 100 And Stages.Total("PackageDepositPercentage") <> 0 Then
		
		ErrorText = NStr("vi = 'Tỷ lệ phần trăm ký cược bao bì theo tất cả giai đoạn phải bằng 100% hoặc 0%';
						|ru = 'Процент залога за тару по всем этапам должен быть равен 100% или 0%';
						|en = 'Percentage of the packaging deposit at all stages should be equal to 100% or 0%'; fa = 'Percentage of the packaging deposit at all stages should be equal to 100% or 0%';
						|it = 'La percentuale di cauzione per imballaggio per tutte le fasi deve essere pari al 100% o 0%';
						|pl = 'Procent kaucji za tarę dla wszystkich etapów powinien wynosić 100% lub 0%';
						|tr = 'Tüm aşamalara ilişkin depozito yüzdesi 100% veya 0% olmalıdır'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"Stages",
			,
			Cancel);
		
	EndIf;
	
	AttributesNotToCheck = New Array;
	AttributesNotToCheck.Add("Stages.PaymentPercentage");
	AttributesNotToCheck.Add("Stages.PackageDepositPercentage");
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	For Each PaymentStage In Stages Do
		
		If Not ValueIsFilled(PaymentStage.PaymentPercentage) And Not ValueIsFilled(PaymentStage.PackageDepositPercentage) Then
			
			ErrorText = NStr("vi = 'Tại dòng của giai đoạn thanh toán cần chỉ ra phần trăm thanh toán hoặc phần trăm ký cược bao bì';
							|ru = 'В строке для этапа должен быть указан процент платежа или процент залога за тару';
							|en = 'Percentage of payment or packaging deposit should be specified in the line for the step'; fa = 'Percentage of payment or packaging deposit should be specified in the line for the step';
							|it = 'Nella riga di fase deve essere indicata la percentuale di pagamento o la percentuale di caparra per imballaggio';
							|pl = 'W wierszu dla etapu musi być wskazany procent płatności lub procent kaucji za tarę';
							|tr = 'Aşama satırında, ödeme yüzdesini veya depozito yüzdesi belirtilmelidir'");
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				"Stages[" + PaymentStage.LineNumber + "]",
				,
				Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	// Let's check whether there are only credit stages of payment in the schedule.
	OnlyCreditMilestonesInSchedule = True;
	For Each TableRow In Stages Do
		If TableRow.PaymentOption <> Enums.CustomerPaymentControlOptions.CreditAfterShipment
			And TableRow.PaymentOption <> Enums.CustomerPaymentControlOptions.CreditPlanned Then
			OnlyCreditMilestonesInSchedule = False;
			Break;
		EndIf;
	EndDo;
	
	If OnlyCreditSteps <> OnlyCreditMilestonesInSchedule Then
		OnlyCreditSteps = OnlyCreditMilestonesInSchedule;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
