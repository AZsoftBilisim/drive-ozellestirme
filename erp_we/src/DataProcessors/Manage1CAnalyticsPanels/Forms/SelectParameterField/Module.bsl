#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ToolTipText = NStr("vi = 'Có thể hạn chế lựa chọn từ bảng ảo ""%1"" theo kỳ được xác định bởi các tham số của nó.
	| Để tự động thiết lập các giá trị tham số trong ""1C:Analytics"", cần chọn trường có kiểu Ngày, bộ lọc của nó sẽ xác định khoảng ngày đối với bảng ảo.
	| Đối với bảng phát sinh trong ""1C:Analytics"" cũng có thể đặt giá trị định kỳ.';
	|ru = 'Выборку из виртуальной таблицы ""%1"" можно ограничить периодом, определяемым ее параметрами.
	| Для автоматической установки значений параметров в ""1С:Аналитике"" необходимо выбрать поле с типом Дата, фильтры для которого будут определять диапазон дат для виртуальной таблицы.
	| Для таблиц оборотов в ""1С:Аналитике"" также можно будет устанавливать значение периодичности.';
	|en = 'You can restrict the selection from the ""%1"" virtual table by the period determined by its parameters.
	|To set parameter values automatically in 1C:Analytics, select the field with the ""Date"" type whose filters will determine the range of dates for the virtual table.
	|You can also set the periodicity value for the turnover tables in 1C:Analytics.'; fa = 'You can restrict the selection from the ""%1"" virtual table by the period determined by its parameters.
	|To set parameter values automatically in 1C:Analytics, select the field with the ""Date"" type whose filters will determine the range of dates for the virtual table.
	|You can also set the periodicity value for the turnover tables in 1C:Analytics.';
	|it = 'Выборку из виртуальной таблицы ""%1"" можно ограничить периодом, определяемым ее параметрами.
	| Для автоматической установки значений параметров в ""1С:Аналитике"" необходимо выбрать поле с типом Дата, фильтры для которого будут определять диапазон дат для виртуальной таблицы.
	| Для таблиц оборотов в ""1С:Аналитике"" также можно будет устанавливать значение периодичности.';
	|pl = 'You can restrict the selection from the ""%1"" virtual table by the period determined by its parameters.
	|To set parameter values automatically in 1C:Analytics, select the field with the ""Date"" type whose filters will determine the range of dates for the virtual table.
	|You can also set the periodicity value for the turnover tables in 1C:Analytics.';
	|tr = '""%1"" sanal tablosundaki veri kümesi, parametreleri tarafından tanımlanan dönemle sınırlandırılabilir.
	| ""1C:Analytics"" kapsamında parametre değerlerinin otomatik olarak yapılandırılmasına ilişkin filtreleri sanal tablo için tarih aralığını belirleyecek olan Tarih tipinde bir alan seçilmesi gerekmektedir.
	| ""1C:Analytics"" içindeki ciro tabloları için dönemsellik değerini yapılandırmak da mümkün olacaktır.'");
	
	TitleOfHintCaption = StrTemplate(ToolTipText, Parameters.TableAlias);
	Items.InscriptionHint.Title = TitleOfHintCaption;
	
	For Each Item In Parameters.ParameterFieldSelectionList Do
		Items.FieldOfParameters.ChoiceList.Add(Item.Value);
	EndDo;
	
	If Parameters.ParameterFieldSelectionList.FindByValue(Parameters.ValueOfParameterField) <> Undefined Then
		FieldOfParameters = Parameters.ValueOfParameterField;
	Else
		Items.InstallButton.Enabled = False;
	EndIf

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FieldOfParametersOnChange(Item)
	
	Items.InstallButton.Enabled = ValueIsFilled(FieldOfParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Set(Command)
	
	Close(FieldOfParameters);
	
EndProcedure

#EndRegion