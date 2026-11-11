
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If PurposeUseKey = "WageReserves" Then
		Title = NStr("vi = 'Nợ phải trả ước tính và dự phòng thanh toán tiền lương';
					|ru = 'Оценочные обязательства и резервы на оплату труда';
					|en = 'Provisions and payroll funds'; fa = 'Provisions and payroll funds';
					|it = 'Оценочные обязательства и резервы на оплату труда';
					|pl = 'Provisions and payroll funds';
					|tr = 'Tahmini yükümlülükler ve bordro yedekleri'");
		AutoTitle = False;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion
