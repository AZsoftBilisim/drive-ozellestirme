
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If Not ProductionServerCall.ProductionIsUsed22() Then
		Raise NStr("vi = 'Được phép tạo đơn đặt hàng vật liệu theo yêu cầu chỉ khi sử dụng quản lý sản xuất, phiên bản 2.2.';
					|ru = 'Формирование заказов материалов по потребностям доступно только при использовании управления производством версии 2.2.';
					|en = 'Generating demand-driven material orders is only available when using production management version 2.2.'; fa = 'Generating demand-driven material orders is only available when using production management version 2.2.';
					|it = 'Формирование заказов материалов по потребностям доступно только при использовании управления производством версии 2.2.';
					|pl = 'Generating demand-driven material orders is only available when using production management version 2.2.';
					|tr = 'Gereksinime göre malzeme siparişlerinin oluşturulması sadece üretim yönetimi sürüm 2.2 kullanıldığında mevcuttur.'");
	EndIf;
	
	Parameters = New Structure("FilterBySupplyType", PredefinedValue("Enum.SupplyTypes.Move"));
	
	OpenForm("DataProcessor.DemandFulfillment.Form", Parameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness);
	
EndProcedure
