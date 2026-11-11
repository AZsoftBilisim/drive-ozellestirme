#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	 
	TitleText = NStr("vi = 'Đặt giá tại %Date%';
					|ru = 'Установка цен на %Date%';
					|en = 'Prices as of %Date%'; fa = 'Prices as of %Date%';
					|it = 'Impostazione prezzi al %Date%';
					|pl = 'Ustawienie cen na %Date%';
					|tr = '%Date% için fiyat yapılandırması'");
	TitleText = StrReplace(TitleText, "%Date%", Format(Parameters.Date, "DLF=DD"));
	Title = TitleText;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Set(Command)
	
	ReturnStructure = New Structure();
	ReturnStructure.Insert("Comment", Comment);
	ReturnStructure.Insert("PriceApplicationOption", PriceApplicationOption);
	Close(ReturnStructure);
	
EndProcedure

#EndRegion
