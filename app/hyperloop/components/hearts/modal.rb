class HeartModal < Hyperloop::Component

  param :heart
  param :trigger

  before_mount do
    mutate.open false
  end

  render(DIV) do
    if state.open
      Sem.Modal(open: state.open) {
        Sem.ModalHeader {
          params.heart.name.nil? || params.heart.name.length == 0 ? "New Heart Card" : params.heart.name
        }
        Sem.ModalContent {
          content
        }
        Sem.ModalActions {
          actions
        }
      }
    else
      Sem.Button(icon: true, labelPosition: 'left', primary: true) {
        Sem.Icon(name: :heart)
        "New Heart Card"
      }.on(:click) { mutate.open true }
    end
  end

  def content
    P { "Please give this Heart Card a good clear name" }
    Sem.Input(placeholder: "Heart Card name", fluid: true, defaultValue: params.heart.name).on(:change) do |e|
      params.heart.name = e.target.value
    end
    BR()
    P { "Choose one or more categories from the HEART framework you would like to track" }
    Categories(heart: params.heart, edit: true)
  end

  def actions
    Sem.Button(primary: true) { "Save" }.on(:click) { save } if params.heart.changed?
    Sem.Button { "Cancel" }.on(:click) { cancel }
  end

  def cancel
    mutate.open false
  end

  def save
    params.heart.save
  end

end
