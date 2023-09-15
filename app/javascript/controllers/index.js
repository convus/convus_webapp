// This file is auto-generated by ./bin/rails stimulus:manifest:update
// Run that command whenever you add a new controller or create them with
// ./bin/rails generate stimulus controllerName

import { application } from './application'

import RatingsFilterController from './ratings_filter_controller'
import SortableRatingsController from './sortable_ratings_controller'
import AdminCurrentHeaderController from './admin_current_header_controller'
import ReloadPageTimerController from './reload_page_timer_controller'

application.register('ratings-filter', RatingsFilterController)
application.register('sortable-ratings', SortableRatingsController)
application.register('admin-current-header', AdminCurrentHeaderController)
application.register('reload-page-timer', ReloadPageTimerController)
