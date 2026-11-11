
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	SelectionParameter = New Structure("Kind", PredefinedValue("Enum.PackingListKinds.Incoming"));
	FormParameters = New Structure("Filter, Title", SelectionParameter, NStr("vi = 'Phiếu đóng gói của nhà cung cấp';
																			|ru = 'Упаковочные листы поставщиков';
																			|en = 'Vendor packing lists'; fa = 'فهرست‌های بسته‌بندی تأمین‌کننده';
																			|it = 'Distinte di imballaggio dei fornitori';
																			|pl = 'Specyfikacje ładunkowe dostawców';
																			|tr = 'Ürün listeleri tedarikçi'"));
	OpenForm("Document.PackingList.ListForm", FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
EndProcedure

#EndRegion

