
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	CoefficientsSum =
		ZoomRatio1
		+ ZoomRatio2
		+ ZoomRatio3
		+ ZoomRatio4
		+ ZoomRatio5
		+ ZoomRatio6
		+ ZoomRatio7
		+ ZoomRatio8
		+ ZoomRatio9
		+ ZoomRatio10
		+ ZoomRatio11
		+ ZoomRatio12;
	
	If CoefficientsSum = 0 Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Cần điền một hoặc nhiều hệ số của lịch biểu khấu hao theo năm';
				|ru = 'Необходимо заполнить один или несколько коэффициентов годового графика амортизации';
				|en = 'Fill in one or several factors of the annual depreciation schedule'; fa = 'Fill in one or several factors of the annual depreciation schedule';
				|it = 'Uno o più coefficienti del programma annuale di ammortamento devono essere compilati';
				|pl = 'Jest wymagane wypełnienie jednego lub kilku współczynników rocznego wykresu amortyzacji';
				|tr = 'Senelik amortisman çizelgesinin bir veya daha fazla katsayısı doldurulmuş olmalıdır'"),
			ThisObject, "ZoomRatio1",, Cancel);
	EndIf;
	
EndProcedure

#EndIf