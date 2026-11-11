
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Text = Parameters.Text;
	
	InformationBar = New FormattedString(Text);
	
	Title = NStr("vi = 'Sẵn sàng chuyển sang phiên bản 11.6';
				|ru = 'Готовность к переходу на редакцию 11.6';
				|en = 'Readiness to migrate to version 11.6'; fa = 'Readiness to migrate to version 11.6';
				|it = 'Readiness to migrate to version 11.6';
				|pl = 'Readiness to migrate to version 11.6';
				|tr = '11.6 revizyonuna geçişe hazırlık'");
	Title = NStr("vi = 'Sẵn sàng chuyển sang phiên bản 2.6';
				|ru = 'Готовность к переходу на редакцию 2.6';
				|en = 'Readiness to migrate to version 2.6'; fa = 'Readiness to migrate to version 2.6';
				|it = 'Readiness to migrate to version 2.6';
				|pl = 'Readiness to migrate to version 2.6';
				|tr = '2.6 revizyonuna geçişe hazırlık'");
EndProcedure

#EndRegion