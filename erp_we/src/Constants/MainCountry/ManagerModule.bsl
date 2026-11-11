#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Performs a check of filling in the "Mainstran" constant
//
Procedure CheckFilling() Export
	
	MainCountry = SettingsValueClientServerCached.MainCountry();
	If Not ValueIsFilled(MainCountry) Then
		Raise NStr("vi = 'Để tiếp tục ghi lại, trong cơ sở thông tin cần điền quốc gia chính
		|Để tùy chỉnh, cần chuyển đến phân hệ ""Danh mục và quản trị""-""Tập đoàn""-""Doanh nghiệp"".';
		|ru = 'Для продожения записи необходимо в информационной базе заполнить основную страну
		|Для настройки необходимо перейти в раздел ""НСИ и администрирование""-""Предприятие""-""Организации"".';
		|en = 'To continue saving, fill in the main country in the infobase
		|To configure it, go to ""Master data and settings"" - ""Enterprise"" - ""Companies"".'; fa = 'To continue saving, fill in the main country in the infobase
		|To configure it, go to ""Master data and settings"" - ""Enterprise"" - ""Companies"".';
		|it = 'Per continuare la registrazione è necessario compilare nell''infobase il paese principale
		|Per l''impostazione è necessario passare alla sezione ""Informazioni di riferimento e amministrazione""-""Impresa""-""Aziende"".';
		|pl = 'Aby kontynuować należy w bazie informacyjnej wypełnić podstawowy kraj
		|W celu ustawienia należy przejść do rozdziału ""Ustawienia""-""Przedsiębiorstwo""-""Firmy"".';
		|tr = 'Kayda devam etmek için infobase''teki ana ülkenin doldurulması gerekir
		|Ayarlamak için ""Master veri ve yönetim"" - ""İşletme"" - ""İş yerleri"" bölümüne git.'");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf