TacticalScreenTopbarEventLogModule.prototype.createDIV = function (_parentDiv) {
	this.mNormalHeight = '13.0rem';
	this.mExtendedHeight = '80.0rem';
	this.mRetractedHeight = '3.5rem';
	this.mExpandDelay = 200;
	this.mMaxVisibleEntries = 150;

	this.mLogState = 'normal';

	var grandpa = _parentDiv.parent();
	_parentDiv.css('opacity', '0');

	var newlog = $('<div class="new-log-container"/>');
	grandpa.append(newlog);
	var width = grandpa.parent().width() / 3;
	newlog.css('width', width);
	newlog.css('background-size', newlog.width() + " " + newlog.height());

	this.mNewLogContainer = newlog;

	var self = this;

	// create: container
	this.mContainer = $('<div class="topbar-event-log-module"/>');
	newlog.append(this.mContainer);

	// create: log container
	var eventLogsContainerLayout = $('<div class="l-event-logs-container"/>');
	eventLogsContainerLayout.css('width', newlog.width() - 50);

	this.mContainer.append(eventLogsContainerLayout);
	this.mEventsListContainer = eventLogsContainerLayout.createList(15);
	this.mEventsListScrollContainer = this.mEventsListContainer.findListScrollContainer();

	this.mEventsListContainer.css('background-size', newlog.width() - 65, + " " + newlog.height());

	// Default font family
	this.mCurrentFontFamily = 'Fira';
	this.mCurrentFontClass = 'font-fira';

	// Default font size (percent)
	this.mCurrentFontSize = '100';
	this.mCurrentFontSizeClass = 'font-size-100';

	// Apply the initial font class to the container
	this.mEventLogsContainerLayout = eventLogsContainerLayout;
	// this.mEventLogsContainerLayout.addClass(this.mCurrentFontClass);

	if (this.mSQHandle) {
		SQ.call(this.mSQHandle, 'getCurrentFontFamily', null, function(fontFamily) {
			if (fontFamily) {
				self.changeFontFamily(fontFamily);
			}
		});
		SQ.call(this.mSQHandle, 'getCurrentFontSize', null, function(fontSize) {
			if (fontSize) {
				self.changeFontSize(fontSize);
			}
		});
	}

	// create: button
	var layout = $('<div class="l-expand-button"/>');
	this.mContainer.append(layout);
	this.ExpandButton = layout.createImageButton(Path.GFX + Asset.BUTTON_OPEN_EVENTLOG, function () {
		self.cycleLogState();
	}, '', 6);
	//this.ExpandButton.css('z-index', '9999999');
	this.expand(false);
};

TacticalScreenTopbarEventLogModule.prototype.changeFontFamily = function (_fontFamily) {
	// Update the current font family
	this.mCurrentFontFamily = _fontFamily;

	// Remove the current font class and add the new one
	if (this.mEventLogsContainerLayout) {
		this.mEventLogsContainerLayout.removeClass(this.mCurrentFontClass);
		var cssClass = 'font-' + _fontFamily.toLowerCase();
		this.mCurrentFontClass = cssClass;
		this.mEventLogsContainerLayout.addClass(cssClass);
	}
};

TacticalScreenTopbarEventLogModule.prototype.changeFontSize = function (_fontSize) {
	// Update the current font size
	this.mCurrentFontSize = _fontSize;

	// Remove current size class and add new
	if (this.mEventLogsContainerLayout) {
		this.mEventLogsContainerLayout.removeClass(this.mCurrentFontSizeClass);
		var cssClass = 'font-size-' + _fontSize;
		this.mCurrentFontSizeClass = cssClass;
		this.mEventLogsContainerLayout.addClass(cssClass);
	}
};

TacticalScreenTopbarEventLogModule.prototype.cycleLogState = function () {
	var nextState;
	switch (this.mLogState) {
		case 'retracted': nextState = 'normal'; break;
		case 'normal': nextState = 'expanded'; break;
		case 'expanded': nextState = 'retracted'; break;
	}
	this.setLogState(nextState);
};

TacticalScreenTopbarEventLogModule.prototype.setLogState = function (_state) {
	if (this.mLogState === _state) return;

	var previousState = this.mLogState;
	var self = this;
	this.mLogState = _state;
	this.mIsExpanded = (_state === 'expanded');

	// Finish any pending animations
	this.mEventsListContainer.velocity("finish", true);

	if (_state === 'retracted') {
		// Snap to retracted instantly
		this.mNewLogContainer.velocity("finish", true);
		this.mNewLogContainer.css({ 'height': '5.5rem', 'overflow': 'hidden' });
		this.mEventLogsContainerLayout.css('height', this.mRetractedHeight);
		this.mEventsListContainer.css({ 'height': this.mRetractedHeight, 'padding-bottom': '0' });
		this.mEventsListContainer.showListScrollbar(false);
		this.mEventsListContainer.trigger('update', true);
		this.mEventsListContainer.scrollListToBottom();
		this.ExpandButton.changeButtonImage(Path.GFX + Asset.BUTTON_OPEN_EVENTLOG);
		return;
	}

	if (previousState === 'retracted') {
		// Restore container from retracted instantly
		this.mNewLogContainer.velocity("finish", true);
		this.mNewLogContainer.css({ 'height': '15.1rem', 'overflow': '' });
		this.mEventLogsContainerLayout.css('height', this.mNormalHeight);
		this.mEventsListContainer.css('height', this.mNormalHeight);
	}

	if (_state === 'normal') {
		// Already at normal sizes (either from retracted restore above, or from expanded finish)
		this.mEventsListContainer.css({ 'height': this.mNormalHeight, 'padding-bottom': '0' });
		this.mEventsListContainer.showListScrollbar(false);
		this.mEventsListContainer.trigger('update', true);
		this.mEventsListContainer.scrollListToBottom();
		this.ExpandButton.changeButtonImage(Path.GFX + Asset.BUTTON_OPEN_EVENTLOG);
		return;
	}

	// Normal => Expanded: animate the list only (container stays at 15.1rem)
	this.mEventsListContainer.velocity(
		{ height: this.mExtendedHeight },
		{
			easing: 'linear',
			duration: this.mExpandDelay,
			begin: function () {
				self.mEventsListContainer.scrollListToElement();
				self.mEventsListContainer.css({ 'padding-bottom': '1.8rem' });
			},
			complete: function () {
				self.mEventsListContainer.trigger('update', true);
				self.mEventsListContainer.scrollListToElement();
				self.mEventsListContainer.showListScrollbar(true);
				self.ExpandButton.changeButtonImage(Path.GFX + Asset.BUTTON_CLOSE_EVENTLOG);
			}
		}
	);
};

TacticalScreenTopbarEventLogModule.prototype.expand = function (_value) {
	var targetState = _value ? 'expanded' : 'normal';
	if (this.mLogState === targetState) {
		this.mEventsListContainer.showListScrollbar(_value);
		return;
	}
	this.setLogState(targetState);
};
