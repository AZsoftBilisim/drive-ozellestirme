#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CanBeEdited = AccessRight("Edit", Metadata.Catalogs.Reserves);
	Items.ListContextMenuChangeSelectedItems.Visible = CanBeEdited;
	
	If PurposeUseKey = "WageReserves" Then
		Title = NStr("vi = 'Nợ phải trả ước tính và dự phòng thanh toán tiền lương';
					|ru = 'Оценочные обязательства и резервы на оплату труда';
					|en = 'Provisions and payroll funds'; fa = 'Provisions and payroll funds';
					|it = 'Оценочные обязательства и резервы на оплату труда';
					|pl = 'Provisions and payroll funds';
					|tr = 'Tahmini yükümlülükler ve bordro yedekleri'");
		AutoTitle = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);

EndProcedure

#EndRegion
